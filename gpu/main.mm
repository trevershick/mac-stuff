#include <CoreFoundation/CFArray.h>
#include <CoreFoundation/CFBase.h>
#include <CoreFoundation/CFCharacterSet.h>
#include <CoreFoundation/CFDictionary.h>
#include <CoreFoundation/CFNumber.h>
#include <CoreFoundation/CFString.h>
#include <Foundation/Foundation.h>
#include <IOKit/ps/IOPSKeys.h>
#include <IOKit/ps/IOPowerSources.h>
#include <IOKit/pwr_mgt/IOPM.h>
#include <MacTypes.h>
#include <Metal/Metal.h>

int main() {
  // Get the default Metal device
  id<MTLDevice> defaultDevice = MTLCreateSystemDefaultDevice();
  if (defaultDevice) {
    NSLog(@"Default GPU: %@", defaultDevice.name);
    NSLog(@"Has support for Metal Feature Set macOS_GPUFamily1_v1: %d",
          [defaultDevice supportsFeatureSet:MTLFeatureSet_macOS_GPUFamily1_v1]);
  }

  // Enumerate all available Metal devices
  NSArray<id<MTLDevice>> *allDevices = MTLCopyAllDevices();
  for (id<MTLDevice> device in allDevices) {
    NSLog(@"Available GPU: %@", device.name);
  }

  return 0;
}
