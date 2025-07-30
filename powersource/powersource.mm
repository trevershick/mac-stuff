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

#include <string>
#include <vector>

enum PowerSourceType {
  Unknown,
  Battery,
  UPS,
  AC,
};

struct PowerSource {
  std::string name;
  PowerSourceType type{Unknown};
  int8_t currentCapacity{0};
  bool charging{false};
};

struct PowerSources {
  PowerSourceType current;
  std::vector<PowerSource> powerSources;
};

PowerSourceType From(CFStringRef ref) {
  if (CFEqual(ref, CFSTR(kIOPMBatteryPowerKey))) {
    return Battery;
  } else if (CFEqual(ref, CFSTR(kIOPMACPowerKey))) {
    return AC;
  } else if (CFEqual(ref, CFSTR(kIOPMUPSPowerKey))) {
    return UPS;
  }
  return Unknown;
}

std::string ToString(PowerSourceType type) {
  switch (type) {
  case AC:
    return "AC";
  case Unknown:
    return "Unknown";
  case Battery:
    return "Battery";
  case UPS:
    return "UPS";
  }
}

bool IsBatteryBacked(PowerSourceType type) {
  switch (type) {
  case AC:
  case Unknown:
    return false;
  case Battery:
  case UPS:
    return true;
  }
}

const CFStringRef keyName = CFSTR("Name");
const CFStringRef keyIsCharging = CFSTR("Is Charging");
const CFStringRef keyCurrentCapacity = CFSTR("Current Capacity");
const CFStringRef keyPowerSource = CFSTR("Power Source State");

void Log(const PowerSources &ps) {
  NSLog(@"Supplying Power: %s", ToString(ps.current).c_str());
  for (size_t i = 0; i < ps.powerSources.size(); i++) {
    if (IsBatteryBacked(ps.powerSources.at(i).type)) {
      NSLog(@"Name: %s, Type: %s, Charging: %s, Current Level: %d",
            ps.powerSources.at(i).name.c_str(),
            ToString(ps.powerSources.at(i).type).c_str(),
            ps.powerSources.at(i).charging ? "Yes" : "No",
            ps.powerSources.at(i).currentCapacity);
    } else {
      NSLog(@"Name: %s, Type: %s", ps.powerSources.at(i).name.c_str(),
            ToString(ps.powerSources.at(i).type).c_str());
    }
  }
}

int main(int argc, char *argv[]) {
  PowerSources sources;

  @autoreleasepool {

    CFTypeRef blob = IOPSCopyPowerSourcesInfo();
    if (blob == nullptr) {
      NSLog(@"Couldn't get blob");
      return 1;
    }

    CFTypeRef sourceType = IOPSGetProvidingPowerSourceType(blob);
    sources.current = From((CFStringRef)sourceType);
    // NSLog(@"Currently Supplying Power: %@", sourceType);

    CFArrayRef list = IOPSCopyPowerSourcesList(blob);
    CFIndex count = CFArrayGetCount(list);
    sources.powerSources.reserve(count);

    for (CFIndex i = 0; i < count; i++) {
      CFTypeRef ps = (CFTypeRef *)CFArrayGetValueAtIndex(list, i);
      CFDictionaryRef dict = IOPSGetPowerSourceDescription(blob, ps);
      if (!dict) {
        NSLog(@"Hmmm dict is empty");
        continue;
      }
      PowerSource source;
      // NSDictionary *nsDictionary = (__bridge NSDictionary *)dict;
      // for (id key in nsDictionary) {
      //   id value = [nsDictionary objectForKey:key];
      //   NSLog(@"Key: %@, Value: %@ Type: %@", key, value,
      //         CFCopyTypeIDDescription(CFGetTypeID(value)));
      // }

      // CFStringRef name;
      // CFStringRef powerSourceState;
      // Boolean isCharging{false};

      bool isBatteryBacked{false};
      // SInt8 currentCapacity{0};

      CFTypeRef value = nullptr;
      // name
      if (CFDictionaryGetValueIfPresent(dict, keyName, &value)) {
        CFIndex length = CFStringGetLength((CFStringRef)value);
        CFIndex maxSize =
            CFStringGetMaximumSizeForEncoding(length, kCFStringEncodingUTF8) +
            1; // +1 for null terminator
        source.name.resize(maxSize);
        CFStringGetCString((CFStringRef)value, (char *)source.name.data(),
                           maxSize, kCFStringEncodingUTF8);
        // NSLog(@"Name is %s", source.name.c_str());
      }

      // power source state
      if (CFDictionaryGetValueIfPresent(dict, keyPowerSource, &value)) {
        source.type = From((CFStringRef)value);
        isBatteryBacked = IsBatteryBacked(source.type);
      }

      // begin is charging
      if (isBatteryBacked &&
          CFDictionaryGetValueIfPresent(dict, keyIsCharging, &value)) {
        source.charging = CFBooleanGetValue((CFBooleanRef)value);
        // NSLog(@"Is Charging %@", source.charging ? CFSTR("Yes") :
        // CFSTR("No"));
      }

      // begin current capacity
      // SInt8 currentCapacity{0};
      if (isBatteryBacked &&
          CFDictionaryGetValueIfPresent(dict, keyCurrentCapacity, &value) &&
          CFNumberGetValue((CFNumberRef)value, CFNumberType::kCFNumberSInt8Type,
                           &source.currentCapacity)) {
        // NSLog(@"Current Capacity: %d", source.currentCapacity);
      }
      sources.powerSources.push_back(std::move(source));
    }

  cleanup:
    // if (isCharging)
    // CFRelease(isCharging);
    if (list)
      CFRelease(list);
    if (blob)
      CFRelease(blob);
  }
  Log(sources);
  return 0;
}
