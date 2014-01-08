class Recliner::ClusterJoiner
  attr_accessor :hostname, :members, :username, :password
  def initialize(options = {})
    @hostname = options[:hostname]
    @username = options[:username]
    @password = options[:password]
    @members = options[:members]
    @members.sort!
  end

  def join
      puts "Top cluster is #{top_cluster(locate_clusters)}"
    if top_cluster(locate_clusters).empty?
      puts "No top cluster found; creating own cluster"
      create_cluster
    elsif ! in_top_cluster(locate_clusters)
      puts "Not in top cluster; joining top cluster!"
      join_cluster(top_cluster(locate_clusters))
    elsif in_top_cluster(locate_clusters)
      puts "I'm in the top cluster; not moving :P"
    else
      puts "I'm not sure what's going on :|"
    end
  end

  def create_cluster
    node = Recliner::Node.new :hostname => hostname, :username => username, :password => password
    node.create_cluster
  end

  def join_cluster(cluster)
    me_node = Recliner::Node.new :hostname => hostname, :username => username, :password => password
    node_in_cluster = Recliner::Node.new :hostname => cluster.sample, :username => username, :password => password
    if me_node.in_cluster? && me_node.cluster_nodes.count > 1
      me_node.leave_cluster
    end
    me_node.join_cluster(node_in_cluster)  
  end

  def in_top_cluster(clusters)
    node = Recliner::Node.new :hostname => hostname, :username => username, :password => password
    top_cluster(clusters).include?(hostname) && node.in_cluster?
  end

  def top_cluster(clusters)
    clusters.sort!{ |x,y| y.count <=> x.count }
    top_clusters = clusters.select{ |cluster| cluster.count == clusters.first.count }
    top_clusters.sort!{ |x,y| y.to_s <=> x.to_s }.first || []
  end
  
  def converged?
    return top_cluster(locate_clusters).count == members.count
  end

  def locate_clusters
    clusters = []
    members_copy = members + [hostname]
    while members_copy.count > 0 do
      member = members_copy.first
      member_node = Recliner::Node.new :hostname => member, :username => username, :password => password
      cluster_nodes = member_node.cluster_nodes.map{ |node| node['hostname'].split(':').first }.sort
      clusters << cluster_nodes
      members_copy -= cluster_nodes
      members_copy -= [member]  
    end
    clusters
  end
end
