{ lib
, writeShellApplication
, util-linux
, firmware
}:

writeShellApplication {
  name = "zmk-uf2-flash";

  runtimeInputs = [
    util-linux
  ];

  text = ''
    available() {
      lsblk -Sno path,model | grep -F 'nRF UF2' | cut -d' ' -f1
    }

    flash=("$@")
    parts=(${toString firmware.parts or ""})

    if [ "''${#flash[@]}" -eq 0 ]; then
      if [ "''${#parts[@]}" -eq 0 ]; then
        flash=("")
      else
        flash=("''${parts[@]}")
      fi
    else
      for part in "''${flash[@]}"; do
        if ! printf '%s\0' "''${parts[@]}" | grep -Fxqz -- "$part"; then
          echo "The '$part' part does not exist in the firmware '"'${firmware.name}'"'"
          exit 1
        fi
      done
    fi

    for part in "''${flash[@]}"; do
      echo -n "Double tap reset and plug in$([ -n "$part" ] && echo " the '$part' part of") the keyboard via USB"
      while ! available > /dev/null; do
        echo -n .
        sleep 1
      done
      echo

      mntdir=$(mktemp -d)

      doas mount -o uid=1000,gid=100 /dev/disk/by-label/XIAO-SENSE "$mntdir"

      cp ${firmware}/*"$([ -n "$part" ] && echo "_$part")".uf2 "$mntdir"

      echo "Firmware copy complete."

      doas umount "$mntdir"

      echo "Done !"
    done
  '';

  meta = with lib; {
    description = "ZMK UF2 firmware flasher";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ /*lilyinstarlight*/ ];
  };
}
