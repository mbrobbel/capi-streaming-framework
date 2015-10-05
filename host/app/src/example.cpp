#include <stdio.h>
#include <stdlib.h>

// libcxl
extern "C" {
  #include "libcxl.h"
}

#define APP_NAME              "example"

#define CACHELINE_BYTES       128                   // 0x80
#define MMIO_ADDR             0x3fffff8             // 0x3fffff8 >> 2 = 0xfffffe

#ifdef  SIM
  #define DEVICE              "/dev/cxl/afu0.0d"
#else
  #define DEVICE              "/dev/cxl/afu1.0d"
#endif

struct wed {
  __u8   volatile status;      // 7    downto 0
  __u8   wed00_a;              // 15   downto 8
  __u16  wed00_b;              // 31   downto 16
  __u32  size;                 // 63   downto 32
  __u64  *source;              // 127  downto 64
  __u64  *dest;                // 191  downto 128
  __u64  wed03;                // 255  downto 192
  __u64  wed04;                // 319  downto 256
  __u64  wed05;                // 383  downto 320
  __u64  wed06;                // 447  downto 384
  __u64  wed07;                // 511  downto 448
  __u64  wed08;                // 575  downto 512
  __u64  wed09;                // 639  downto 576
  __u64  wed10;                // 703  downto 640
  __u64  wed11;                // 767  downto 704
  __u64  wed12;                // 831  downto 768
  __u64  wed13;                // 895  downto 832
  __u64  wed14;                // 959  downto 896
  __u64  wed15;                // 1023 downto 960
};

int main (int argc, char *argv[]) {

  // open afu device
  struct cxl_afu_h *afu = cxl_afu_open_dev ((char*) (DEVICE));
  if (!afu) {
    perror ("cxl_afu_open_dev");
    return -1;
  }

  // setup wed
  struct wed *wed0 = NULL;
  if (posix_memalign ((void **) &(wed0), CACHELINE_BYTES, sizeof(struct wed))) {
    perror ("posix_memalign");
    return -1;
  }

  wed0->status = 0;

  // attach afu and pass wed address
  if (cxl_afu_attach (afu, (__u64) wed0) < 0) {
    perror ("cxl_afu_attach");
    return -1;
  }

  printf("AFU has started.\n");

  // map mmio
  if ((cxl_mmio_map (afu, CXL_MMIO_BIG_ENDIAN)) < 0) {
    perror("cxl_mmio_map");
    return -1;
  }

  uint64_t rc;

  // wait for afu
  while (!wed0->status) {
    cxl_mmio_read64(afu, MMIO_ADDR, &rc);
    printf("Response counter: %lu\n", rc);
  }

  printf("AFU is done.\n");

  cxl_mmio_unmap (afu);
  cxl_afu_free (afu);

  return 0;

}
