#!/usr/bin/env ruby

require 'rubygems'
require 'dataflow'
include Dataflow
f = lambda do |state, m|
  newstate=state+m
  puts "old state = #{state}, message = #{m}, new state = #{newstate} "
	newstate
end
init=0
port=Dataflow::Variable.new
local do |port, stream|
	  unify port, Dataflow::Port.new(stream)
  Thread.new do 
    stream.inject(init) { |state, m| f.call(state,m) }
  end
end




require 'rubygems'
require 'dataflow'
include Dataflow
class PortObject
	def initialize(init, f)
    port=Dataflow::Variable.new
    local do |port, stream|
    	  unify port, Dataflow::Port.new(stream)
      Thread.new do 
        stream.inject(init) { |state, m| 
				  case  m[0]
					  when :message then 
						  f.call(state,m[1]) 
						when :state then
						  unify m[1], state
							state
						else
							state
					end
				}
      end
    end
		@port=port
	end
	def send(m)
	  @port.send([:message, m] )
	end
	def state
	  resp = Dataflow::Variable.new
		@port.send([:state, resp])
		resp.__wait__
		resp
	end
end
f=lambda do |state,m|
  puts "m=#{m} and newstate=#{state+m}"
  state+m
end
p=PortObject.new(0,f)
p.send 1


require 'rubygems'
require 'dataflow'
include Dataflow
class ActiveObject
	def initialize(init, klass)
    port=Dataflow::Variable.new
		@o = klass.new(*init)
    local do |port, stream|
    	unify port, Dataflow::Port.new(stream)
      Thread.new do 
        stream.inject(init) { |state, m| 
				  case  m[0]
					  when :message then 
						  @o.send(m[1][0], *m[1].drop(1))
						else
							state
					end
				}
      end
    end
		@port=port
	end
	def send(m)
	  @port.send([:message, m] )
	end
	def state
	  @o.state
	end
end
class Counter
  def initialize(i)
	  puts "setting state to #{i}"
	  @count=i
	end
	def add(i, mult)
	  puts "adding #{i}"
	  @count+=i*mult
	end
	def sub(i)
	  @count-=i
	end
	def state
	  puts "returning state #{@count}"
	  @count
	end
end
a=ActiveObject.new(0,Counter)
a.send([:add,5,2])
a.state
a.send([:sub,2])
a.state
a.send([:add,50,3])
a.state
