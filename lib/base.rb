class DocYoSelf
  @@tests = {}
  @@lock = ::Mutex.new
  attr_accessor :request, :response, :note, :file, :skip

  def initialize(options = {})
    assign_options(options)
  end

  def run!(caller, options = {})
    assign_options(options) #legacy support
    
    if caller # guess the options from the test object (self)
      assign_default_options(caller)
    end
    @file ||= self.class::Conf.output_file

    [:request, :response, :file].each do |var|
      unless self.public_send(var)
        raise "`DocYoSelf.new(#{var}: ...)` is missing. You may also use `DocYoSelf.run!(self)` to generate this option." 
      end
    end
    add_to_tests
  end

  def assign_options(options)
    @file ||= options[:file]
    @request ||= options[:request] 
    @response ||= options[:response] 
    @note ||= options[:note]
  end

  def assign_default_options(caller)
    assign_options({
      request: caller.request,
      response: caller.response
    })
    assign_options({
      file: caller.class.name.underscore.gsub('/', '_').sub(/_test$/,'') + '.md',
      note: caller.method_name.sub(/^test[\d_]*/, '').gsub('_', ' ')
    }) if caller.respond_to?(:method_name) && caller.method_name #minitest only...
  end

  def skip!
    @skip = true
  end

  def add_to_tests
    return if skip
    raise "No DocYoSelf output_file specified" if blank?(file)

    folder = self.class::Conf.output_folder.try(:sub, /\/$/, '')
    raise "No DocYoSelf output_folder specified" if blank?(folder)
    
    file_path = "#{folder}/#{file}" 

    @@lock.synchronize do
      @@tests[file_path] ||= []
      @@tests[file_path] << self
    end
  end

  def compile_template
    template = self.class::Conf.template
    raise "No DocYoSelf template specified" unless template
    ERB.new(template).result binding
  end

  def blank?(object)
    #because we might not be in Rails world
    object !~ /[^[:space:]]/
  end
  
  # START CLASS METHODS
  class << self
    def tests
      @@tests
    end

    def clean_up!
      @@lock.synchronize do
        @@tests = {}
      end
    end

    def sort_by_url(tests)
      return unless tests
      tests.reject{|x| x.request.nil?}.sort! do |x, y|
        "#{x.request.method} #{x.request.path}" <=> "#{y.request.method} #{y.request.path}"
      end
    end

    def output_testcases_to_file
      tests.each do |file, tests|
        File.delete file if File.exists? file
        File.open(file, 'a') do |file|
          sort_by_url(tests).each do |test|
            file.write(test.compile_template)
          end
        end
      end
    end

    def finish!
      output_testcases_to_file
      clean_up!
    end

    def run!(*args)
      self.new.run!(*args)
    end

    #Legacy Support
    def old_run!(request, response, output_file = nil)
      run!(nil, request: request, response: response, file: output_file)
    end

    def config(&block)
      yield(self::Conf)
    end
  end
  # END CLASS METHODS
end
