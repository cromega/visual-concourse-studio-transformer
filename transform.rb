require "json"
require "yaml"

RESOURCE_ATTRIBUTE_LOOKUP = {
  "git" => %w(uri branch private_key),
  "s3" => %w(access_key_id secret_access_key region_name endpoint bucket regexp),
  "http request" => %w(method url)
}

class NodePipeline
  RESOURCE_TYPES= ["http request"]

  def initialize(json)
    @objects = JSON.parse(json)
  end

  def resources
    @_resources ||= @objects.select { |obj| RESOURCE_TYPES.include? obj["type"] }
  end

  def jobs
    @_jobs ||= @objects.select { |obj| obj["type"] == "function" }
  end

  def inputs_of(job_id)
    resources.select { |obj| obj["wires"].flatten.include? job_id }
  end

  def outputs_of(job_id)
    job = jobs.find { |job| job["id"] == job_id }
    resources.select { |obj| job["wires"].flatten.include? obj["id"] }
  end
end

def generate_plan(inputs, job, outputs)
  plan = []

  inputs.each do |input|
    name = input["name"]
    res = {"get" => name}
    res["params"] = job[name]["get"] if job[name]
    plan << res
  end

  (job["tasks"] || []).each_pair do |name, file|
    plan << {
     "task" => name,
     "file" => file
   }
 end

  outputs.each do |output|
    name = output["name"]
    res = {"put" => name}
    res["params"] = job[name]["put"] if job[name]
    plan << res
  end

  plan
end

def get_attributes_of(resource)
  type_attrs = RESOURCE_ATTRIBUTE_LOOKUP[resource["type"]]
  raise "unknown resource type" unless type_attrs

  attributes = {}
  type_attrs.each do |type_attr|
    attributes[type_attr] = resource[type_attr]
  end

  attributes
end

def generate_resources(resources)
  resources.map do |resource|
    {
      "name" => resource["name"],
      "type" => resource["type"],
      "source" => get_attributes_of(resource)
    }
  end
end

node_pipeline = NodePipeline.new(File.read($*.shift))

pipeline = {"resources" => [], "jobs" => []}

pipeline["resources"] = generate_resources(node_pipeline.resources)

node_pipeline.jobs.each do |job|
  inputs = node_pipeline.inputs_of(job["id"])
  outputs = node_pipeline.outputs_of(job["id"])
  job_meta = JSON.parse(job["func"])

  job_obj = {"name" => job["name"]}
  job_obj["plan"] = generate_plan(inputs, job_meta, outputs)
  pipeline["jobs"] << job_obj
end

puts pipeline.to_yaml
