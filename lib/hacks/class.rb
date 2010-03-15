class Class
 def def_each(*method_names, &block)
   mapping = method_names.last.is_a?(Hash) && method_names.pop || {}

   method_names.each do |method_name|
     define_method method_name do
        instance_exec method_name, &block
     end
   end

   mapping.each_pair do |method_name, mapped_name|
    define_method method_name do
      instance_exec mapped_name, &block
    end
   end
 end

 def to_proc
   proc(&method(:new))
 end
end