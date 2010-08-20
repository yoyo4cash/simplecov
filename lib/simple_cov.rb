module SimpleCov
  class CoverageDataError < StandardError; end;
  VERSION = File.read(File.join(File.dirname(__FILE__), '../VERSION'))
  
  class << self
    attr_accessor :running, :result # TODO: Remove result?
    
    #
    # Sets up SimpleCov to run against your project.
    #
    # TODO: Explain config! Add default adapters!
    #
    def start(adapter=nil, &block)
      unless "1.9".respond_to?(:encoding)
        warn "WARNING: SimpleCov is activated, but you're not running Ruby 1.9 - no coverage analysis will happen"
        return false
      end
      require 'coverage'
      load_adapter(adapter) unless adapter.nil?
      Coverage.start
      puts "Script: #{$0.inspect}"
      puts "Args: '#{$*.inspect}' or #{ARGV.inspect}"
      configure(&block) if block_given?
      @result = nil
      self.running = true
    end
    
    #
    # Returns the result for the currntly runnig coverage run
    #
    def result
      @result ||= SimpleCov::Result.new(Coverage.result) if running
    ensure
      self.running = false
    end
    
    #
    # Returns the project name - currently assuming the last dirname in
    # the SimpleCov.root is this
    #
    def project_name
      File.basename(root.split('/').last).capitalize.gsub('_', ' ')
    end
    
    #
    # Applies the configured filters to the given array of SimpleCov::SourceFile items
    #
    def filtered(files)
      result = files.clone
      filters.each do |filter|
        result = result.select {|source_file| filter.passes?(source_file) }
      end
      result
    end
    
    #
    # Applies the configured groups to the given array of SimpleCov::SourceFile items
    #
    def grouped(files)
      grouped = {}
      grouped_files = []
      groups.each do |name, filter|
        grouped[name] = files.select {|source_file| !filter.passes?(source_file)}
        grouped_files += grouped[name]
      end
      if groups.length > 0 and (other_files = files.reject {|source_file| grouped_files.include?(source_file)}).length > 0
        grouped["Ungrouped"] = other_files
      end
      grouped
    end
    
    # 
    # Applies the adapter of given name on SimpleCov configuration
    #
    def load_adapter(name)
      adapters.load(name)
    end
  end
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__)))
require 'simple_cov/configuration'
SimpleCov.send :extend, SimpleCov::Configuration
require 'simple_cov/adapters'
require 'simple_cov/source_file'
require 'simple_cov/result'
require 'simple_cov/filter'
require 'simple_cov/formatter'
require 'simple_cov/merge_helpers'

# Default configuration
SimpleCov.configure do
  formatter SimpleCov::Formatter::SimpleFormatter
  # Exclude files outside of SimpleCov.root
  load_adapter 'root_filter'
end

at_exit do
  SimpleCov.at_exit.call
end