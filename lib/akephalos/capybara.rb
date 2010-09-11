# Driver class exposed to Capybara. It implements Capybara's full driver API,
# and is the entry point for interaction between the test suites and HtmlUnit.
#
# This class and +Capybara::Driver::Akephalos::Node+ are written to run on both
# MRI and JRuby, and is agnostic whether the Akephalos::Client instance is used
# directly or over DRb.
class Capybara::Driver::Akephalos < Capybara::Driver::Base

  # Akephalos-specific implementation for Capybara's Node class.
  class Node < Capybara::Node

    # @api capybara
    # @param [String] name attribute name
    # @return [String] the attribute value
    def [](name)
      name = name.to_s
      case name
      when 'checked'
        node.checked?
      else
        node[name.to_s]
      end
    end

    # @api capybara
    # @return [String] the inner text of the node
    def text
      node.text
    end

    # @api capybara
    # @return [String] the form element's value
    def value
      node.value
    end

    # Set the form element's value.
    #
    # @api capybara
    # @param [String] value the form element's new value
    def set(value)
      if tag_name == 'textarea'
        node.value = value.to_s
      elsif tag_name == 'input' and type == 'radio'
        click
      elsif tag_name == 'input' and type == 'checkbox'
        if value != self['checked']
          click
        end
      elsif tag_name == 'input'
        node.value = value.to_s
      end
    end

    # Select an option from a select box.
    #
    # @api capybara
    # @param [String] option the option to select
    def select(option)
      result = node.select_option(option)

      if result == nil
        options = node.options.map(&:text).join(", ")
        raise Capybara::OptionNotFound, "No such option '#{option}' in this select box. Available options: #{options}"
      else
        result
      end
    end

    # Unselect an option from a select box.
    #
    # @api capybara
    # @param [String] option the option to unselect
    def unselect(option)
      unless self[:multiple]
        raise Capybara::UnselectNotAllowed, "Cannot unselect option '#{option}' from single select box."
      end

      result = node.unselect_option(option)

      if result == nil
        options = node.options.map(&:text).join(", ")
        raise Capybara::OptionNotFound, "No such option '#{option}' in this select box. Available options: #{options}"
      else
        result
      end
    end

    # Trigger an event on the element.
    #
    # @api capybara
    # @param [String] event the event to trigger
    def trigger(event)
      node.fire_event(event.to_s)
    end

    # @api capybara
    # @return [String] the element's tag name
    def tag_name
      node.tag_name
    end

    # @api capybara
    # @return [true, false] the element's visiblity
    def visible?
      node.visible?
    end

    # Drag the element on top of the target element.
    #
    # @api capybara
    # @param [Node] element the target element
    def drag_to(element)
      trigger('mousedown')
      element.trigger('mousemove')
      element.trigger('mouseup')
    end

    # Click the element.
    def click
      node.click
    end

    private

    # Return all child nodes which match the selector criteria.
    #
    # @api capybara
    # @return [Array<Node>] the matched nodes
    def all_unfiltered(selector)
      nodes = []
      node.find(selector).each { |node| nodes << Node.new(driver, node) }
      nodes
    end

    # @return [String] the node's type attribute
    def type
      node[:type]
    end
  end

  attr_reader :app, :rack_server

  def self.driver
    @driver ||= Akephalos::Client.new
  end

  def initialize(app)
    @app = app
    @rack_server = Capybara::Server.new(@app)
    @rack_server.boot if Capybara.run_server
  end

  def visit(path)
    browser.visit(url(path))
  end

  def source
    page.source
  end

  def body
    page.modified_source
  end

  def current_url
    page.current_url
  end

  def find(selector)
    nodes = []
    page.find(selector).each { |node| nodes << Node.new(self, node) }
    nodes
  end

  def execute_script(script)
    page.execute_script script
  end

  def evaluate_script(script)
    page.evaluate_script script
  end

  def page
    browser.page
  end

  def browser
    self.class.driver
  end

  def wait
    false
  end

private

  def url(path)
    rack_server.url(path)
  end

end
