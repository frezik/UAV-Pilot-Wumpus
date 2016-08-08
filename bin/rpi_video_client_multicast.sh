#!/bin/bash
MULTICAST_IP=244.1.1.1
IFACE=wlan0

set -x

gst-launch-1.0 udpsrc port=5000 \
      auto-multicast=true multicast-group=${MULTICAST_IP} multicast-iface=${IFACE} \
    ! gdpdepay \
    ! rtph264depay \
    ! avdec_h264 \
    ! videoconvert \
    ! autovideosink sync=false
