require 'erb'

GENERATION_MESSAGE_TEMPLATE = <<~MESSAGE.freeze
  ####################################
  # NOTICE: This is a generated file #
  ####################################
  #
  # To update this file please edit the relevant template and run the generation
  # task `<%= task_name.nil? ? 'rake generate:all' : "rake \#{task_name}" %>`
MESSAGE

class GenerationMessage
  attr_reader :task_name

  def initialize(task_name = nil)
    @task_name = task_name
  end
end

ERB.new(GENERATION_MESSAGE_TEMPLATE).def_method(GenerationMessage, 'render')
