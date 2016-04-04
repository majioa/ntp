require 'ntp/server/base'
require 'dbus'
require 'pry'

class NTP::Server::Control
   NUM = NTP::Server::Base::NUM
   DEFAULT_PORT = 17890

   def usage
      "Usage: ntp-mock-server [start|stop|restart|status|time <time>|reset]"
   end

   def status
      if connection
         connection.status
      else
         "not running"
      end
   end

   def start port = DEFAULT_PORT
      fork { NTP::Server::Base.run(port || DEFAULT_PORT) }

      if wait_for_connection
         connection.start
      else
         "can't run"
      end
   end

   def stop
      connection.stop
   rescue DBus::Error
   end

   def restart
      [ stop, start ].join("\n")
   end

   def time time
      connection.time(time.to_s)
   end

   def reset
      connection.reset
   end

   private

   def try_get_connection obj
      if obj
         obj.introspect
         obj.default_iface = "org.ruby.ntp_mock.server#{NUM}"
         p "CONNECTED"
         @connection = obj
      else
         @connection = nil
         nil
      end
   rescue DBus::Error
   end

   def connection
      @connection || try_get_connection(self.object)
   end

   def wait_for_connection timeout = 3
      object = wait_for_object
      begin
         begin
            Timeout::timeout(timeout) do
               begin ;end until try_get_connection(object)
            end
         rescue Timeout::Error
            p "TO"
         end
      end until @connection
      @connection
   end

   def object
      @object || get_object
   end

   def get_object
      service = @bus.service("org.ruby.ntp_mock#{NUM}")
      @object = service.object("/org/ruby/NTPMockInstance#{NUM}")
   rescue DBus::Error
      @connection = nil
      @object = nil
   end

   def wait_for_object timeout = 3
      Timeout::timeout(timeout) do
         begin ;end until get_object
      end
      @object
   rescue Timeout::Error
      nil
   end

   def initialize
      @bus = DBus::SystemBus.instance
      try_get_connection(get_object)
   end
end
