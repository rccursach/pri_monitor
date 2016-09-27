
class Parser
  def initialize
  end
  def parse_binstr binstr
    delimiter = [0xFE, 0xFE].pack('c*')
    id_fast = [0xAA, 0xAA].pack('c*')
    id_slow = [0xBB, 0xBB].pack('c*')

    packets_arr = binstr.split(delimiter)
    #puts packets_arr.inspect

    fast_packets = []
    slow_packets = []

    packets_arr.each_with_index do |p, idx|
      
      packets_arr[idx] = p.gsub(delimiter, '');
      
      if packets_arr[idx].start_with?(id_fast)
        fast_packets << packets_arr[idx].gsub(id_fast, '')
      elsif packets_arr[idx].start_with?(id_slow)
        slow_packets << packets_arr[idx].gsub(id_slow, '')
      end
          
    end

    #puts fast_packets.inspect
    #puts slow_packets.inspect

    res = []
    parse_fast(fast_packets).each do |p|
      res << p
    end
    parse_slow(slow_packets).each do |p|
      res << p
      #puts p
    end

    #puts res.inspect
    return res

  end

  def parse_fast fast_arr
    fast_objs = []
    fast_arr.each do |p|
      accel_x = p[0..1].unpack('s>')[0]
      accel_y = p[2..3].unpack('s>')[0]
      accel_z = p[4..5].unpack('s>')[0]

      gyro_x = p[6..7].unpack('s>')[0]
      gyro_y = p[8..9].unpack('s>')[0]
      gyro_z = p[10..11].unpack('s>')[0]

      imu_time = p[12..15].reverse().unpack('L')[0]

      fast_objs << {
        type: 'F1',
        accel_x: accel_x, accel_y: accel_y, accel_z: accel_z,
        gyro_x: gyro_x, gyro_y: gyro_y, gyro_z: gyro_z,
        imu_time: imu_time
       }
    end
    return fast_objs
  end

  def parse_slow slow_arr
    slow_objs = []
    slow_arr.each do |p|
      temp1 = p[0..1].unpack('s>')[0] / 16.0
      temp2 = p[2..3].unpack('s>')[0] / 16.0
      weight = p[4..7].unpack('l>')[0] #this one is signed long
      rtc_time = p[8..11].reverse().unpack('L')[0]

      slow_objs << {
        type: 'S1',
        t1: temp1, t2: temp2,
        weight: weight,
        rtc_time: rtc_time
      }
    end
    return slow_objs
  end


end