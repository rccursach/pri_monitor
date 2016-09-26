require "ruxbee"
require "thread"
require "json"
require "pp"

require_relative "parser"
require_relative "cache"
require_relative "db"

module Pri
  class Monitor

    def initialize dev, speed
      cache_opt = {host: 'localhost', port: 6379}
      @xbee     = XBee.new dev, speed, :API_S1
      @parser   = Parser.new
      @cache    = PRI_FRUTAS::Cache.new cache_opt[:host], cache_opt[:port], 'pri_nodes', 'pri_reg'
      @db       = Db.new 'pri_data', 'sensor_data'
      @buff_mtx = Mutex.new
    end

    def process_data res_arr

      puts "new thread of #{Thread.list.count} many"

      @buff_mtx.synchronize do
        #[TODO: Insert many!]
        res_arr.each do |res|
          #puts res.inspect
          packets = @parser.parse_binstr res[:data]
          packets.each do |p|
            #if p[:accel_x].nil?
              pp p
            #end
            @cache.update_node res[:address].to_s, p.to_json
            # @cache.insert_data res[:address].to_s, p.to_json
            @db.insert_one p
          end
        end #end each arr
      end #end synchronize
    end

    def run
      buff1 = []
      buff2 = []
      lim = 50
      curr_buff = buff1

      loop do
        begin
          res = @xbee.getresponse
          if not res.nil? and res.api_identifier == '81'

            res = {rssi: res.rssi, address: res.address_16_bits.to_i(2), api_frame_id: res.api_identifier, data: res.cmd_data}
            curr_buff << res
            puts "ok - #{curr_buff.length}"

            # check not only if limit is reached but if the last thread
            # is done working on that buffer
            if curr_buff.length > lim #and not @buff_mtx.locked?
              Thread.new(curr_buff, &method(:process_data))
              curr_buff = (curr_buff === buff1 ? buff2 : buff1)
              curr_buff.clear
            end

          elsif not res.nil? and res.api_identifier != '81'
            puts "DEBUG: got XBee/ZigBee frame with #{res.api_identifier}"
          elsif res.nil?
            #puts 'Response is nil, sleeping 1 sec'
            print '.'
            sleep 1
          end
        rescue => e
          puts e
        end
      end
    end
  end

end