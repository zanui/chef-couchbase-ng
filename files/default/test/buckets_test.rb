describe_recipe "couchbase::buckets" do
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  MiniTest::Chef::Resources.register_resource :couchbase_bucket, :username, :password

  node['couchbase']['buckets'].each do |bucket_name, bucket_config|
    bucket_config = {} if bucket_config.nil? or [TrueClass, FalseClass].include?(bucket_config.class)

    describe "a bucket called #{bucket_name}" do
      let :bucket do
        couchbase_bucket(bucket_name, {
          :username => node["couchbase"]["server"]["username"],
          :password => node["couchbase"]["server"]["password"],
        })
      end

      it "exists" do
        assert bucket.exists
      end

      it "is correct type" do
        bucket.must_have :type, bucket_config['type']
      end

      it "has correct number of replicas" do
        bucket.must_have :replicas, bucket_config['replicas']
      end

      it "has correct quota" do
        bucket.must_have :memory_quota_mb, node['couchbase']['cluster']['memory_quota_mb']
      end if bucket_config['memory_quota_mb']

      it "has correct quota" do
        bucket.must_have :memory_quota_mb, (node['couchbase']['cluster']['memory_quota_mb'] * bucket_config['memory_quota_percent']).to_i
      end if bucket_config['memory_quota_percent']

      it "has correct saslpassword" do
        bucket.must_have :saslpassword, bucket_config['saslpassword']
      end if bucket_config['saslpassword']

    end
  end
end
