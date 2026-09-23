// Copyright 2026 Timofey Brukhanchik (asyncbtd)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module mem

import context
import math

@[typedef]
pub struct C.MEMORYSTATUSEX {
	dwLength                u32
	dwMemoryLoad            u32
	ullTotalPhys            u64
	ullAvailPhys            u64
	ullTotalPageFile        u64
	ullAvailPageFile        u64
	ullTotalVirtual         u64
	ullAvailVirtual         u64
	ullAvailExtendedVirtual u64
}

@[typedef]
pub struct C.PERFORMANCE_INFORMATION {
	cb                 u32
	commit_total       usize
	commit_limit       usize
	commit_peak        usize
	physical_total     usize
	physical_available usize
	system_cache       usize
	kernel_total       usize
	kernel_paged       usize
	kernel_nonpaged    usize
	page_size          usize
	handle_count       u32
	process_count      u32
	thread_count       u32
}

fn C.GlobalMemoryStatusEx(buf &C.MEMORYSTATUSEX) int

fn C.GetPerformanceInfo(buf &C.PERFORMANCE_INFORMATION, cb u32) int

// virtual_memory_with_context reports virtual memory on Windows.
pub fn virtual_memory_with_context(_ context.Context) !VirtualMemoryStat {
	mut status := C.MEMORYSTATUSEX{
		dwLength: u32(C.MEMORYSTATUSEX.sizeof)
	}
	if C.GlobalMemoryStatusEx(&status) == 0 {
		return error('GlobalMemoryStatusEx failed')
	}
	mut ret := VirtualMemoryStat{
		total:        status.ullTotalPhys
		available:    status.ullAvailPhys
		free:         status.ullAvailPhys
		used_percent: f64(status.dwMemoryLoad)
	}
	ret.used = ret.total - ret.available
	return ret
}

// swap_memory_with_context reports swap memory on Windows.
pub fn swap_memory_with_context(_ context.Context) !SwapMemoryStat {
	mut used_percent := 0.0
	if C.vpsutil_paging_file_usage_percent(&used_percent) == 0 {
		return error('PDH paging file usage counter failed')
	}
	mut perf := C.PERFORMANCE_INFORMATION{
		cb: u32(C.PERFORMANCE_INFORMATION.sizeof)
	}
	if C.GetPerformanceInfo(&perf, perf.cb) == 0 {
		return error('GetPerformanceInfo failed')
	}
	page_size := u64(perf.page_size)
	total_phys := u64(perf.physical_total) * page_size
	total_sys := u64(perf.commit_limit) * page_size
	total := total_sys - total_phys
	mut ret := SwapMemoryStat{
		total: total
	}
	if total > 0 {
		used := u64(0.01 * used_percent * f64(total))
		ret.used = used
		ret.free = total - used
		ret.used_percent = round1(used_percent)
	} else {
		ret.used_percent = 0
		ret.used = 0
		ret.free = 0
	}
	return ret
}

// swap_devices_with_context lists paging files on Windows.
pub fn swap_devices_with_context(_ context.Context) ![]SwapDevice {
	return enum_page_files()
}

fn enum_page_files() ![]SwapDevice {
	mut list := C.VpsutilPageFileList{}
	if C.vpsutil_collect_page_files(&list) == 0 {
		return error('EnumPageFilesW failed')
	}
	mut devices := []SwapDevice{}
	for i in 0 .. list.count {
		pf := list.items[i]
		devices << SwapDevice{
			name:       wide_z_to_string(&pf.name[0])
			used_bytes: pf.used_bytes
			free_bytes: pf.free_bytes
		}
	}
	return devices
}

fn wide_z_to_string(wstr &u16) string {
	return unsafe { string_from_wide(wstr) }
}

fn round1(x f64) f64 {
	return math.round(x * 10.0) / 10.0
}
