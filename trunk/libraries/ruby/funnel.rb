#!/usr/bin/env ruby

require 'socket'
require 'timeout'
require 'osc'

require 'funnel/configuration'
require 'funnel/event'
require 'funnel/port'
require 'funnel/filter'

module Funnel
  (GAINER, ARDUINO, XBEE, FIO) = Array(Configuration::GAINER..Configuration::FIO)
  (IN, OUT, PWM) = Array(Configuration::IN..Configuration::PWM)

  class Funnel
    MINIMUM_SAMPLING_INTERVAL = 10

    attr_accessor :auto_update

    def port_def_to_str(type)
      case type
      when Port::AIN
        return "analog input"
      when Port::DIN
        return "digital input"
      when Port::AOUT
        return "analog output (PWM)"
      when Port::DOUT
        return "digital output"
      end
    end

    def initialize(host, port, config, interval)
      begin
        @command_port = TCPSocket.open(host, port)
        puts "command port: #{@command_port.addr.at(2)}, #{@command_port.addr.at(1)}"
      rescue
        raise RuntimeError, "can't connect to the command port (#{port}) of the funnel_server"
      end
      begin
        @notification_port = TCPSocket.open(host, port + 1)
        puts "notification port: #{@notification_port.addr.at(2)}, #{@notification_port.addr.at(1)}"
      rescue
        raise RuntimeError, "can't connect to the notification port (#{port + 1}) of the funnel_server"
      end

      send_command(OSC::Message.new('/reset'), 5)
      send_command(OSC::Message.new('/configure', 'i' * config.to_a.size, *config.to_a))
      @port = []
      @port_count = 0

      @ain_ports = config.ain_ports
      @din_ports = config.din_ports
      @aout_ports = config.aout_ports
      @dout_ports = config.dout_ports
      @analog_pins = config.analog_pins
      @digital_pins = config.digital_pins
      @button = config.button
      @led = config.led

      init_ports(config.to_a)

      if interval < MINIMUM_SAMPLING_INTERVAL
        then interval = MINIMUM_SAMPLING_INTERVAL
      end
      send_command(OSC::Message.new('/samplingInterval', 'i', interval))
      @sampling_interval = interval

      @auto_update = true
      @updated_port_indices = Array.new(@port_count, false)

      Thread.new do
        loop do
          packet = @notification_port.recv(8192)
          begin
            OSC::Packet.decode(packet).each do |time, message|
              id = message.to_a[0]
              from = message.to_a[1]
              counts = message.to_a.length - 2
              counts.times do |i|
                port(from + i).value = message.to_a[2 + i]
              end
            end
          rescue EOFError
            puts "notification port: EOF error"
          end
        end
      end

      send_command(OSC::Message.new('/polling', 'i', 1))
    end

    def send_command(command, seconds_to_wait = 1)
      @command_port.send(command.encode, 0)
      packet = nil
      begin
        timeout(seconds_to_wait) {packet = @command_port.recv(4096)}
        OSC::Packet.decode(packet).each do |time, message|
          # puts "received: #{message.address}, #{message.to_a}"
          if message.to_a[0] < ErrorEvent::NO_ERROR then
            case message.to_a[0]
            when ErrorEvent::ERROR:
              puts "ERROR: #{message.to_a[1]}"
            when ErrorEvent::REBOOT_ERROR:
              raise REBOOT_ERROR, "REBOOT_ERROR: #{message.to_a[1]}"
            when ErrorEvent::CONFIGURATION_ERROR:
              raise RuntimeError, "CONFIGURATION_ERROR: #{message.to_a[1]}"
            end
          end
        end
      rescue TimeoutError
        puts "TimeoutError: command = #{command.address}"
      rescue EOFError
        puts "EOFError: packet = #{packet}"
      end
    end

    def init_ports(config)
      @port.clear
      config.each do |type|
        puts "port(#{@port_count}): #{port_def_to_str(type)}"
        port = Port.new(@port_count, type)
        @port.push(port)
        if port.type == Port::AOUT or port.type == Port::DOUT then
          port.add_event_listener(PortEvent::CHANGE) do |event|
            if (@auto_update) then
              send_output_command(event.target.number, event.target.value)
            else
              @updated_port_indices[event.target.number] = true
            end
          end
        end
        @port_count = @port_count + 1
      end
      @max_port_number = @port_count - 1
    end

    def port(number)
      if (number < 0) or (number > @max_port_number) then
        raise ArgumentError, "port is not available at #{number}"
        return nil
      end
      @port[number]
    end

    def analog_input(number)
      return if @ain_ports == nil
      raise ArguentError, "analog input is not availabe at #{number}" if @ain_ports.at(number) == nil
      @port[@ain_ports.at(number)]
    end

    def digital_input(number)
      return if @din_ports == nil
      raise ArguentError, "digital input is not availabe at #{number}" if @din_ports.at(number) == nil
      @port[@din_ports.at(number)]
    end

    def analog_output(number)
      return if @aout_ports == nil
      raise ArguentError, "analog output is not availabe at #{number}" if @aout_ports.at(number) == nil
      @port[@aout_ports.at(number)]
    end

    def digital_output(number)
      return if @dout_ports == nil
      raise ArguentError, "digital output is not availabe at #{number}" if @dout_ports.at(number) == nil
      @port[@dout_ports.at(number)]
    end

    def analog_pin(number)
      return if @analog_pins == nil
      raise ArguentError, "analog pin is not availabe at #{number}" if @analog_pins.at(number) == nil
      @port[@analog_pins.at(number)]
    end

    def digital_pin(number)
      return if @digital_pins == nil
      raise ArguentError, "digital pin is not availabe at #{number}" if @digital_pins.at(number) == nil
      @port[@digital_pins.at(number)]
    end

    def button(number = 0)
      return if @button == nil
      raise ArguentError, "button is not availabe at #{number}" if @button.at(number) == nil
      @port[@button.at(number)]
    end

    def led(number = 0)
      return if @led == nil
      raise ArguentError, "LED is not availabe at #{number}" if @led.at(number) == nil
      @port[@led.at(number)]
    end

    def send_output_command(start, values)
      command = OSC::Message.new('/out', 'iif', 0, start, *values)
      send_command(command)
    end

    def update()
      start = 0
      output_values = []
      was_updated = false

      @updated_port_indices.each_with_index do |updated, index|
        if updated then
          output_values.push(@port[index].value)
          @updated_port_indices[index] = false
          start = index unless was_updated
        elsif was_updated then
          send_output_command(start, output_values) unless index == 0
          output_values = []
        end
        was_updated = updated
      end
      send_output_command(start, output_values)
    end

  end
end


if __FILE__ == $0
  module Funnel
    gio = Funnel.new('localhost', 9000, Gainer::MODE1, 33)

    gio.port(0).filters = [SetPoint.new(0.5, 0.1)]
    gio.port(0).add_event_listener(PortEvent::CHANGE) do |event|
      puts "ain 0: #{event.target.value}"
    end

    gio.port(17).on(PortEvent::RISING_EDGE) do
      puts "button: pressed"
    end

    gio.port(17).on PortEvent::FALLING_EDGE do
      puts "button: released"
    end

    Osc.service_interval = 33
    osc = Osc.new(Osc::SQUARE, 2.0, 0)
    gio.port(16).filters = [osc]
    osc.reset
    osc.start

    sleep(5)
  end
end
