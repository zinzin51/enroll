class Workflow::Workflow
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
  include Mongoid::Userstamp
  include SetCurrentUser

  embeds_many :workflow_steps

  attr_reader :workflow_steps

  field :person_id, type: BSON::ObjectId

  validate :person_id

  def current_step
  end

  def completed_steps
  end 

  def remaining_steps
  end

  def completed_workflow?
  end

  def initialize
    super
    yaml_hash = from_yaml("config/workflow/financial_assistance.yml")
    @workflow_steps = {}
    initialize_steps_from_hash(yaml_hash)
  end

  def initialize_steps_from_hash(yaml_hash)
    yaml_hash["steps"].each do |key, value|
      @workflow_steps[key] = value
    end

    @workflow_steps.each do |key, value|
      Workflow::Workflowstep.from_hash(value)
    end
  end

  def from_yaml(filename)
    begin
      yaml_hash = YAML.load_file(filename)
    rescue Exception => e
      puts "The input YAML file is badly formatted---#{e.inspect}" unless Rails.env.test?
    end

    return yaml_hash
  end

  def person=(new_person)
    self.person_id = new_person._id
    @person = new_person
  end

  def person
    return @person if @person.present?
    Person.find(self.person_id)
  end
end
