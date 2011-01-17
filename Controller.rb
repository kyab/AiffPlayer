# Controller.rb
# AiffPlayer
#
# Created by koji on 10/12/17.
# Copyright 2010 __MyCompanyName__. All rights reserved.

framework "CoreAudio"

class Controller
	attr_accessor :label_freq,:slider_freq,:wave_view, :label_filename, :check_lowpass;
	attr_accessor :start_btn, :stop_btn;
	attr_accessor :state;
	
	def awakeFromNib()
		NSLog("Controller.rb awaked from nib")
		NSLog("Running on MacRuby " + MACRUBY_VERSION)
		
		gc = NSGarbageCollector.defaultCollector()
		if (gc)
			NSLog("gc enabled")
		else
			NSLog("gc disabled")
		end
		
		@auProcessor = AUProcessor.new
	end
	
	def hello(sender)
		puts "Controller#hello"
	end
	
	def initCoreAudio(sender)
		@auProcessor.initCoreAudio
		@start_btn.enabled= true;
	
	end
	
	def start(sender)
		@auProcessor.start
		@start_btn.enabled = false
		@stop_btn.enabled = true;
		@state = :play
	end
	
	def stop(sender)
		#puts "Controller.stop"
		@auProcessor.stop
		@stop_btn.enabled = false
		@start_btn.enabled = true
		@state = :stop
	end
	
	def loadAiff(file)
		@check_lowpass.state = NSOffState
		@auProcessor.loadAiff(file)
		
		@label_filename.stringValue = file
		
		#set the timer
		NSTimer.scheduledTimerWithTimeInterval(0.01, 
									target:self,
									selector: 'ontimer:',
									userInfo:nil,
									repeats:true)
									
		@wave_view.setAiff(@auProcessor.aiff)
		
	end
	
	def load(sender)

		loadAiff("/Users/koji/work/m/sound_files/MilkeyWay.aif");
		#loadAiff("/Users/koji/work/m/sound_files/DrumnBossa.aif");
		#loadAiff("/Users/koji/work/m/sound_files/kaera_orange.aif");
		#loadAiff("/Users/koji/work/m/sound_files/kaera_orange_short.aif");
		#loadAiff("/Users/koji/work/m/sound_files/kaera_orange_supershort.aif");
		
		

	end
	
	def ontimer(timer)
		#redraw
		return if @state != :play
		@wave_view.piriodicUpdate
	end
	
	def lowpass(sender)
		p sender.state
		if (sender.state == NSOnState)
			@auProcessor.setUselowpass(true)
		else
			@auProcessor.setUselowpass(false)
		end

		@wave_view.forceRedraw();
	end
	
	def listOutputDevices(sender)
		@auProcessor.listOutputDevices
	end
	
	def listOutputDevices_ruby(sender)
		pSize = Pointer.new("I");
		r = AudioHardwareGetPropertyInfo(KAudioHardwarePropertyDevices, pSize, nil)
		puts pSize[0]
		
		count = pSize[0] / 4 #is there any way to do sizeof(type??)
		pDeviceIDs = Pointer.new("I", count)
		
		r = AudioHardwareGetProperty(KAudioHardwarePropertyDevices, pSize, pDeviceIDs)
		
		deviceIDs = Array.new
		count.times do |i|
			deviceIDs << pDeviceIDs[i]
		end
		#AudioStreamRangedDescription
	
		deviceIDs.each do |devID|
			pName = Pointer.new("c",256)
			pSize = Pointer.new("I")
			pSize.assign(256)
			#p devID
			
			#AudioStreamBasicDescriptions
			
			r = AudioDeviceGetProperty(devID,0,0,KAudioDevicePropertyDeviceName, pSize,pName)
			#p pSize[0]
			name = String.new
			(pSize[0]-1).times do |n|	#NULL文字も入ってくるので -1。
				name << pName[n]
			end
			puts "device - id:#{devID} name:#{name}"
		end
		
		
		#kAudioStreamPropertyAvailableVirtualFormats
	end
	
	#freq slider handler (should use Cocoa-Bind)
	def freq_slider_changed(sender)
		@label_freq.stringValue = sender.intValue().to_s
		@auProcessor.setFreq(sender.intValue)
	end
	
	#delegation method
	def applicationShouldTerminateAfterLastWindowClosed(sender)
		puts "last window closed"
		return true
	end
end
	