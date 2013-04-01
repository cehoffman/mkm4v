# Purpose of this class
#
# This class is used to make an interface for a presenter class
# This way the presenter doesn't have to care if the source class
# implements all the methods because they will be there with
# default values.  It also protects the presenter and source
# from carring about errors that occur while collecting the information.
# The errors will be silently swallowed and default values will be
# returned instead.
module Mp4::Source
  module Template
    SingleItemTags = %w|name artist album_artist album grouping composer comments
                        genre released track disk tempo show number network
                        id season description long_description rating lyrics
                        copyright encoding_tool encoded_by cnID|
    MultipleItemTags = %w|cast directors codirectors producers writers studio|
    Tags = SingleItemTags + MultipleItemTags

    def self.included(klass)
      klass.class_variable_set(:@@tags, {})

      Tags.each do |tag|
        # Define class functions for each type of tag
        # These will take in a block that when an
        # instance of the class is called with a method
        # of the same name will evaluate the block and
        # store the returned value
        klass.instance_eval <<-EOS,__FILE__,__LINE__
          def #{tag}(&block)
            class_variable_get(:@@tags)[:#{tag}] = block
          end
        EOS

        # default = SingleItemTags.include?(tag) ? '""' : '[]'

        # Need to instance eval the block so it gets the methods
        # from the instance in the block
        klass.class_eval <<-EOS,__FILE__,__LINE__
          def #{tag}
            @#{tag} ||= begin
                          instance_eval(&self.class.class_variable_get(:@@tags)[:#{tag}]) || nil
                        rescue Exception => e
                          nil
                        end
          end
        EOS
      end
    end
  end
end