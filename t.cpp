#ifdef _MSVC_STL_DESTRUCTOR_TOMBSTONES
#define CMDLINE_DEFINED 1
#define CMDLINE_VALUE _MSVC_STL_DESTRUCTOR_TOMBSTONES
#else
#define CMDLINE_DEFINED 0
#define CMDLINE_VALUE -1
#endif

static const int cmdlineValue = CMDLINE_VALUE;

#include <cstdio>
#include <vector>

int main()
{
	std::vector<int> v{1, 2, 3};
	std::printf("cmdline_defined=%d cmdline_value=%d after_stl=%d\n", CMDLINE_DEFINED, cmdlineValue, _MSVC_STL_DESTRUCTOR_TOMBSTONES);
	return 0;
}
