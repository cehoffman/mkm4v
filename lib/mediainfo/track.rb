module MediaInfo::Track
  def self.included(klass)
    klass.extend ClassMethods
    klass.property :id, 'ID', Integer
  end

  def initialize(source, track)
    @source, @track, @track_type = source, track, self.class.to_s[/::(\w+)Track$/, 1].downcase.to_sym

    self.class.class_variable_get(:@@properties).each do |name, param, converter|
      instance_variable_set("@#{name}".to_sym, converter.call(info(param)))
    end

    self.class.class_variable_get(:@@initializations).each { |block| instance_eval &block }
  end

  def info(query)
    @source.track_info @track_type, @track, query
  end

  Integer = ->(raw) { raw.to_i }
  Float = ->(raw) { raw.to_f }

  module ClassMethods
    def self.extended(klass)
      klass.class_variable_set(:@@properties, [])
      klass.class_variable_set(:@@initializations, [])
    end

    def property(name, param, converter = ->(raw) { raw } )
      attr_reader name
      class_variable_get(:@@properties) << [name, param, converter]
    end

    def initialized(&block)
      class_variable_get(:@@initializations) << block if block_given?
    end
  end
end