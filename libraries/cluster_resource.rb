require "chef/resource"
require File.join(File.dirname(__FILE__), "credentials_attributes")

class Chef
  class Resource
    class CouchbaseCluster < Resource
      include Couchbase::CredentialsAttributes

      def cluster(arg=nil)
        set_or_return(:cluster, arg, :kind_of => String, :name_attribute => true)
      end

      def exists(arg=nil)
        set_or_return(:exists, arg, :kind_of => [TrueClass, FalseClass], :required => true)
      end

      def memory_quota_mb(arg=nil)
        set_or_return(:memory_quota_mb, arg, :kind_of => Integer, :required => false, :callbacks => {
        	"must be at least 256" => lambda { |quota| !quota.nil? && quota >= 256 }
      	})
      end

      def members(arg=nil)
        set_or_return(:members, arg, :kind_of => Array, :required => false)
      end

      def members_finder(arg=nil)
        set_or_return(:members_finder, arg, :kind_of => Proc, :required => false)
      end

      def converge_timeout(arg=120)
        set_or_return(:converge_timeout, arg, :kind_of => Integer, :required => false)
      end

      def initialize(*)
        super
        @action = :nothing
        @allowed_actions.push(:converge,:create_if_missing)
        @resource_name = :couchbase_cluster
      end
    end
  end
end
