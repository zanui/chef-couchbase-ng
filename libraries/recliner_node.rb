require 'json'
require 'net/http'
require 'uri'

class Recliner::Node
  include Recliner::Client
  attr_accessor :hostname, :username, :password
  def initialize( options = {} )
    defaults = {
      :hostname => 'localhost'
    }
    options = defaults.merge(options)
    if options[:hostname].nil? || options[:password].nil?
      raise ArgumentError, 'username and password mandatory for cluster management.'
    end
    @hostname = options[:hostname]
    @username = options[:username]
    @password = options[:password]
  end

    def cluster_nodes
      cluster_details['nodes'] || []
    end

    def cluster_details
      begin
        JSON.parse(get('/pools/default').body)
      rescue
        {}
      end
    end

    def join_node(node)
      params = { 'hostname' => "#{node.hostname}:8091", 'user' => node.username, 'password' => node.password}
      post('/controller/addNode', params)
    end

    def eject_node(node)
      params = { 'otpNode' => "ns_1@#{node.hostname}" }
      post('/controller/ejectNode', params)
    end

    def join_cluster(cluster_node)
      cluster_node.join_node(self)
    end

    def leave_cluster
      return true if !in_cluster?
      kickme_node = Recliner::Node.new(
          :hostname => cluster_nodes.select { |node| node['hostname'].split(':').first && node['status'] != 'unhealthy' }.sample['hostname'].split(':').first,
          :password => password,
          :username => username
      )
      puts "Asking #{kickme_node.hostname} to kick me"
      kickme_node.eject_node(self)
    end
 
    def create_cluster
      params = { 'username' => username, 'password' => password, 'port' => '8091'}
      post('settings/web',params)
    end

    def fail_node(node)
      params = { 'otpNode' => "ns_1@#{node.hostname}" }
      post('/controller/failOver',params)
    end

    def node_in_cluster?(node)
    end

    def in_cluster?
      cluster_details.empty? ? false : true
    end
end
