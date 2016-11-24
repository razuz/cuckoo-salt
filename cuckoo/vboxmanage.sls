modifyvm_rdp:
  cmd.run:
    - name: VBoxManage modifyvm "Win7_64bit_node1" --vrde on --vrdeport 9001 --vrdeaddress=0.0.0.0 --accelerate3d off --accelerate2dvideo on --vrdeauthtype null --vrdeauthlibrary null --vrdemulticon on --vrdereusecon on --vrdevideochannel off
    - runas: cuckoo
