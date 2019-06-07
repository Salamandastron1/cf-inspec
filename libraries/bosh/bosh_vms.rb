# require 'bosh_api'
require 'pp'

class BoshVms < Inspec.resource(1)
  name 'bosh_vms'
  desc "Verify info about a bosh deployment's vms"

  example "
    describe bosh_vms('cf-warden') do
      its('diego_cell') { should all include('vm_type' => '2xlarge') }
    end
  "

  include ObjectTraverser

  attr_reader :params

  def initialize(deployment_name)
    @params = {}
    begin
      @bosh_client = BoshClient.new
      @params = @bosh_client.get("/deployments/#{deployment_name}/vms?format=full")
                            .group_by { |vm_stats| vm_stats['job_name'] }
    rescue => e
      puts "Error during processing: #{$ERROR_INFO}"
      puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"

      raise Inspec::Exceptions::ResourceFailed, "BOSH API error: #{e}"
    end
  end

  def method_missing(*keys)
    # catch bahavior of rspec its implementation
    # @see https://github.com/rspec/rspec-its/blob/master/lib/rspec/its.rb#L110
    keys.shift if keys.is_a?(Array) && keys[0] == :[]
    value(keys)
  end

  def value(key)
    # uses ObjectTraverser.extract_value to walk the hash looking for the key,
    # which may be an Array of keys for a nested Hash.
    extract_value(key, params)
  end
end
