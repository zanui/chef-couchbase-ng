require "chef/provider"
require 'timeout'
require File.join(File.dirname(__FILE__), "client")
require File.join(File.dirname(__FILE__), "cluster_data")
require File.join(File.dirname(__FILE__), "recliner/recliner")

class Chef
  class Provider
    class CouchbaseCluster < Provider
      include Couchbase::Client
      include Couchbase::ClusterData

      def load_current_resource
        @current_resource = Resource::CouchbaseCluster.new @new_resource.name
        @current_resource.cluster @new_resource.cluster
        @current_resource.exists !!pool_data
        @current_resource.memory_quota_mb pool_memory_quota_mb if @current_resource.exists
      end

      def action_create_if_missing
        unless @current_resource.exists
          post "/pools/#{@new_resource.cluster}", "memoryQuota" => @new_resource.memory_quota_mb
          @new_resource.updated_by_last_action true
          Chef::Log.info "#{@new_resource} created"
        end
      end

      def action_converge
        if @new_resource.members.nil? and @new_resource.members_finder.nil?
          raise ArgumentError, 'members or members_finder must be defined to locate cluster!'
        end
        if converged?
          Chef::Log.info('Node already converged on cluster.')
        else
          Timeout.timeout(@new_resource.converge_timeout) {
            until converged?
              Chef::Log.warn('Converging...')
              joiner.join
              sleep 4
            end
          }
          if joiner.converged? then Chef::Log.info('Node has converged on cluster.') end
        end
      end

      private
      def converged?
        joiner.converged?
      end

      def joiner
        Recliner::ClusterJoiner.new(
          :hostname => local_ip,
          :username => @new_resource.username,
          :password => @new_resource.password,
          :members => members
        )
      end

      def local_ip
        ip_v4s =  node['network']['interfaces'].values.inject([]) { |arr,elem| elem['addresses'].each { |key,val| arr.push(key) if val['family'] == 'inet' };arr }
        ip_v4s.select { |ip| ip =~ /#{members.first.split('.').first}/ }.first
      end

      def members
        @new_resource.members || @new_resource.members_finder.call
      end
    end
  end
end
