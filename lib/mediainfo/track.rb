module MediaInfo::Track
  def self.included(klass)
    klass.extend ClassMethods
    klass.property :id, 'ID', Integer
  end

  def initialize(source, track)
    @source, @track = source, track

    self.class.class_variable_get(:@@properties).each do |name, param, converter|
      instance_variable_set(name, converter.call(info(param)))
    end

    self.class.class_variable_get(:@@initializations).each { |block| instance_eval &block }
  end

  def info(query)
    @source.track_info self.class.class_variable_get(:@@track_type), @track, query
  end

  Integer = ->(raw) { raw.to_i }
  Float = ->(raw) { raw.to_f }
  String = ->(raw) { raw }

  module ClassMethods
    def self.extended(klass)
      klass.class_variable_set(:@@properties, [])
      klass.class_variable_set(:@@initializations, [])
      klass.class_variable_set(:@@track_type, klass.name[/::(\w+)Track$/, 1].downcase.to_sym)
    end

    def property(name, param, converter = String )
      attr_reader name.to_sym
      class_variable_get(:@@properties) << ["@#{name}".to_sym, param, converter]
    end

    def initialized(&block)
      class_variable_get(:@@initializations) << block if block_given?
    end
  end
end