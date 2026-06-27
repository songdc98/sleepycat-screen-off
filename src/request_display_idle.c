#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <stdio.h>

int main(void) {
  mach_port_t main_port = kIOMainPortDefault;

  io_registry_entry_t display_wrangler = IORegistryEntryFromPath(
      main_port, "IOService:/IOResources/IODisplayWrangler");
  if (display_wrangler == MACH_PORT_NULL) {
    fprintf(stderr, "Could not find IODisplayWrangler\n");
    return 1;
  }

  kern_return_t result = IORegistryEntrySetCFProperty(
      display_wrangler, CFSTR("IORequestIdle"), kCFBooleanTrue);
  IOObjectRelease(display_wrangler);

  if (result != KERN_SUCCESS) {
    fprintf(stderr, "IORequestIdle failed: %d\n", result);
    return 2;
  }

  return 0;
}
