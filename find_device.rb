#!/usr/bin/ruby

require 'json'
require 'time'

class GeoptimaFile
  def initialize(jfile)
    @jfile = jfile
    @loaded = false
    load
  end

  def loaded?
    @loaded
  end

  def get_jfile
    @jfile
  end

  def get_deviceid
    deviceid = nil
    ['id', 'udid', 'imei', 'imsi'].each do |m|
      deviceid = self.send("get_#{m}")
      break if deviceid.to_s.size > 0 && 'not available' != deviceid
    end
    deviceid
  end

  def get_id
    get_subscriber['id']
  end

  def get_imei
    get_subscriber['imei']
  end

  def get_imsi
    get_subscriber['imsi']
  end

  def get_udid
    get_subscriber['UDID']
  end

  def get_mcc
    get_subscriber['MCC']
  end

  def get_mnc
    get_subscriber['MNC']
  end

  def get_app_nbame
    get_geoptima['AppName']
  end

  def get_subscriber
    @geoptima['subscriber'] || {}
  end

  def get_platform
    get_subscriber['Platform']
  end

  def get_start
    get_subscriber['start']
  end

  def get_start_timestamp
    begin
      Time.parse(get_start).to_i
    rescue
      puts "Parse start failed. start:#{get_start}, file: #{get_jfile}"
      nil
    end
  end


  def ios?
    get_platform =~ /iphone.*/i|| false   #return false rather than nil for friendly display
  end

  def after_start?(start_date)
    return false if get_start_timestamp.nil?
    get_start_timestamp > Time.parse(start_date).to_i
  end

  private
  def load
    file_contents = nil
    File.open(@jfile, 'r') do |f|
      file_contents = f.read
    end
    if file_contents
      begin
      file_hash = JSON.parse(file_contents)
      @geoptima = file_hash['geoptima']
      @loaded = true
      rescue
        puts "Error when reading file: #{@jfile}"
      end

    end
  end

  def get_geoptima
    @geoptima || {}
  end

end



# GEOPTIMA_DIR = "/home/henry/code/rubyworkspace/"
GEOPTIMA_DIR = "/ciq/data/geoptima"
DEVICE_DIRS=[]
MCC = '502'
START_TIME='2014-11-01'


def find_ios_device(dir)
  json_files = Dir.glob("#{dir}/**/*.json") || []
  json_files.sort_by! {|fp| File.basename fp}
  json_files.each do |fpath|
    #try to reduce folder which is already scanned

    if DEVICE_DIRS.include?(fpath)
      next
    end

    # matchdata = fpath.match( /.*\/([^_]*)(_\d{13})(_\d{13})?\.json$/ ) #if filename match deviceid_clienttime_servertime.json


    gfile = GeoptimaFile.new(fpath)

    if gfile.loaded?
      #try to found IOS device and JSON file
      if(!FOUND_DEVICE_MAPPINGS.keys.include?(gfile.get_deviceid) && gfile.ios? && gfile.get_mcc == MCC && gfile.after_start?(START_TIME))
        FOUND_DEVICE_MAPPINGS.merge!(gfile.get_deviceid  => fpath)
      end
      DEVICE_DIRS << fpath
    else
      puts "Failed to load file: #{fpath}"
    end
    puts DEVICE_DIRS[-1]
    break;
  end
end

FOUND_DEVICE_MAPPINGS={}
Dir.chdir(GEOPTIMA_DIR)
Dir.glob("*").each do |dir|
  next unless File.directory?(dir)
  devicepath = File.join(GEOPTIMA_DIR, dir)
  find_ios_device(devicepath)
end
puts "IOS Device: count: #{FOUND_DEVICE_MAPPINGS.keys.count}"
puts "IOS Device:  deviceids: #{FOUND_DEVICE_MAPPINGS.keys}"
puts "IOS Device:  files: #{FOUND_DEVICE_MAPPINGS.values.sort_by! {|v| File.basename(v) }}"




