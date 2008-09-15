on sendBugReport(bxVersion)
	tell application "Mail"
		set msg to make new outgoing message
		set the subject of msg to "BootXChanger Bug Report"
		make new to recipient at beginning of to recipients of msg with properties {address:"support@namedfork.net"}
		
		-- set message body
		set the content of msg to "BootXChanger Bug Report (build " & bxVersion & ")" & return & Â
			"The most likely reason for BootXChanger not working is that it can't determine the location of the boot image in your mac's bootloader, therefore the bug report includes some hardware and software information about your mac, and the bootloader." & return & "You may include other information you think is relevant, and send this e-mail." & Â
			return & return & return & Â
			(do shell script "system_profiler -detailLevel mini SPHardwareDataType SPSoftwareDataType") & return & "Bootloader:" & return
		
		-- attach bootloader
		if (do shell script "arch") is "i386" then
			make new attachment with properties {file name:"/usr/standalone/i386/boot.efi"} at after the last paragraph of msg
		else
			make new attachment with properties {file name:"/usr/standalone/ppc/bootx.bootinfo"} at after the last paragraph of msg
		end if
		
		set the visible of msg to true
		activate
	end tell
end sendBugReport