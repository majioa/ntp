require 'eventmachine'
require 'dbus'

class NTP::Server::Base < DBus::Object
   NUM = 12
   attr_accessor :host, :port, :pipe_in, :pipe_out, :pid,
       :gap_reader, :gap_writer

   dbus_interface "org.ruby.ntp_mock.server#{NUM}" do
   #       # Create a hello method in that interface.
      dbus_method :start, "out ret:s" do
         p "start"
         Thread.new do
            EventMachine::run do
               # returns NTP::Server::Handler::EM_CONNECTION_CLASS
               EventMachine::open_datagram_socket(self.host, self.port, self.handler)
            end
         end
         p "start1"
         [ "started NTP mock server on #{self.host}:#{self.port}." ]
      end

      dbus_method :stop, "out ret:s" do
         Thread.new do
            Process.exit(true)
         end
         [ "stopped" ]
      end

      dbus_method :status, "out ret:s" do
         p "status"
         [ 'listening...' ]
      end

      dbus_method :time, "in time:s, out ret:s" do |time|
         p "time #{time}"
         self.handler.gap = Time.parse(time).utc - Time.now.utc
         [ "set time base to #{new_time.utc}..." ]
      end

      dbus_method :reset, "out ret:s" do
         p "reset"
         self.handler.gap = 0
         [ "reset time base" ]
      end
   end

   def initialize port = 123
      self.host = 'localhost'
      self.port = port
      self.handler.origin_time = Time.now
      self.handler.gap = 0
      super("/org/ruby/NTPMockInstance#{NUM}") # to dbus
    end

   def handler
       NTP::Server::Handler
   end

   def self.run port
      Process.setsid
      bus = DBus::SystemBus.instance
      service = bus.request_service("org.ruby.ntp_mock#{NUM}")
      server = self.new(port)
      service.export(server)
      loop = DBus::Main.new
      loop << bus
      loop.run
   end
end
