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

import os
import math
import context
import common

struct ExVirtualMemory {
mut:
	active_anon   u64
	inactive_anon u64
	active_file   u64
	inactive_file u64
	unevictable   u64
	percpu        u64
	kernel_stack  u64
}

const swaps_filename = 'swaps'

const name_col = 0
const total_col = 2
const used_col = 3

fn host_proc(ctx context.Context, parts ...string) string {
	mut root := common.getenv(ctx, common.host_proc_env_key)
	if root == '' {
		root = '/proc'
	}
	if parts.len == 0 {
		return root
	}
	return os.join_path(root, ...parts)
}

// virtual_memory_with_context reports virtual memory using ctx for HOST_PROC overrides.
pub fn virtual_memory_with_context(ctx context.Context) !VirtualMemoryStat {
	vm, _ := fill_from_meminfo(ctx)!
	return vm
}

// swap_devices_with_context lists swap devices using ctx for HOST_PROC overrides.
pub fn swap_devices_with_context(ctx context.Context) ![]SwapDevice {
	path := host_proc(ctx, swaps_filename)
	lines := os.read_lines(path)!
	return parse_swaps_lines(path, lines)
}

// swap_memory_with_context reports swap memory using ctx for HOST_PROC overrides.
pub fn swap_memory_with_context(ctx context.Context) !SwapMemoryStat {
	mut total := u64(0)
	mut swap_free := u64(0)
	if vpsutil_linux_swap_bytes(&total, &swap_free) == 0 {
		return error('sysinfo failed')
	}
	mut ret := SwapMemoryStat{
		total: total
		free:  swap_free
	}
	ret.used = ret.total - ret.free
	if ret.total != 0 {
		ret.used_percent = f64(ret.total - ret.free) / f64(ret.total) * 100.0
	} else {
		ret.used_percent = 0
	}
	filename := host_proc(ctx, 'vmstat')
	lines := os.read_lines(filename) or {
		return error("couldn't read ${filename}: ${err}")
	}
	for line in lines {
		fields := line.split_by_space()
		if fields.len < 2 {
			continue
		}
		key := fields[0]
		value := fields[1].u64()
		match key {
			'pswpin' { ret.sin = value * 4 * 1024 }
			'pswpout' { ret.sout = value * 4 * 1024 }
			'pgpgin' { ret.pg_in = value * 4 * 1024 }
			'pgpgout' { ret.pg_out = value * 4 * 1024 }
			'pgfault' { ret.pg_fault = value * 4 * 1024 }
			'pgmajfault' { ret.pg_maj_fault = value * 4 * 1024 }
			else {}
		}
	}
	return ret
}

fn fill_from_meminfo(ctx context.Context) !(VirtualMemoryStat, ExVirtualMemory) {
	filename := host_proc(ctx, 'meminfo')
	lines := os.read_lines(filename) or {
		return error("couldn't read ${filename}: ${err}")
	}

	mut memavail := false
	mut active_file := false
	mut inactive_file := false
	mut s_reclaimable := false

	mut ret := VirtualMemoryStat{}
	mut ret_ex := ExVirtualMemory{}

	for line in lines {
		parts := line.split(':')
		if parts.len != 2 {
			continue
		}
		key := parts[0].trim_space()
		value := parts[1].trim_space().replace(' kB', '')

		match key {
			'MemTotal' { ret.total = parse_kb(value)! }
			'MemFree' { ret.free = parse_kb(value)! }
			'MemAvailable' {
				ret.available = parse_kb(value)!
				memavail = true
			}
			'Buffers' { ret.buffers = parse_kb(value)! }
			'Cached' { ret.cached = parse_kb(value)! }
			'Active' { ret.active = parse_kb(value)! }
			'Inactive' { ret.inactive = parse_kb(value)! }
			'Active(anon)' { ret_ex.active_anon = parse_kb(value)! }
			'Inactive(anon)' { ret_ex.inactive_anon = parse_kb(value)! }
			'Active(file)' {
				ret_ex.active_file = parse_kb(value)!
				active_file = true
			}
			'Inactive(file)' {
				ret_ex.inactive_file = parse_kb(value)!
				inactive_file = true
			}
			'Unevictable' { ret_ex.unevictable = parse_kb(value)! }
			'Percpu' { ret_ex.percpu = parse_kb(value)! }
			'Writeback' { ret.write_back = parse_kb(value)! }
			'WritebackTmp' { ret.write_back_tmp = parse_kb(value)! }
			'Dirty' { ret.dirty = parse_kb(value)! }
			'Shmem' { ret.shared = parse_kb(value)! }
			'Slab' { ret.slab = parse_kb(value)! }
			'SReclaimable' {
				ret.sreclaimable = parse_kb(value)!
				s_reclaimable = true
			}
			'SUnreclaim' { ret.sunreclaim = parse_kb(value)! }
			'KernelStack' { ret_ex.kernel_stack = parse_kb(value)! }
			'PageTables' { ret.page_tables = parse_kb(value)! }
			'SwapCached' { ret.swap_cached = parse_kb(value)! }
			'CommitLimit' { ret.commit_limit = parse_kb(value)! }
			'Committed_AS' { ret.committed_as = parse_kb(value)! }
			'HighTotal' { ret.high_total = parse_kb(value)! }
			'HighFree' { ret.high_free = parse_kb(value)! }
			'LowTotal' { ret.low_total = parse_kb(value)! }
			'LowFree' { ret.low_free = parse_kb(value)! }
			'SwapTotal' { ret.swap_total = parse_kb(value)! }
			'SwapFree' { ret.swap_free = parse_kb(value)! }
			'Mapped' { ret.mapped = parse_kb(value)! }
			'VmallocTotal' { ret.vmalloc_total = parse_kb(value)! }
			'VmallocUsed' { ret.vmalloc_used = parse_kb(value)! }
			'VmallocChunk' { ret.vmalloc_chunk = parse_kb(value)! }
			'HugePages_Total' { ret.huge_pages_total = parse_meminfo_u64(value)! }
			'HugePages_Free' { ret.huge_pages_free = parse_meminfo_u64(value)! }
			'HugePages_Rsvd' { ret.huge_pages_rsvd = parse_meminfo_u64(value)! }
			'HugePages_Surp' { ret.huge_pages_surp = parse_meminfo_u64(value)! }
			'Hugepagesize' { ret.huge_page_size = parse_kb(value)! }
			'AnonHugePages' { ret.anon_huge_pages = parse_kb(value)! }
			else {}
		}
	}

	ret.cached += ret.sreclaimable

	if !memavail {
		if active_file && inactive_file && s_reclaimable {
			ret.available = calculate_avail_vmem(ctx, ret, ret_ex)
		} else {
			ret.available = ret.cached + ret.free
		}
	}
	ret.used = ret.total - ret.available
	if ret.total != 0 {
		ret.used_percent = f64(ret.used) / f64(ret.total) * 100.0
	}

	return ret, ret_ex
}

fn calculate_avail_vmem(ctx context.Context, ret VirtualMemoryStat, ret_ex ExVirtualMemory) u64 {
	fn_path := host_proc(ctx, 'zoneinfo')
	lines := os.read_lines(fn_path) or {
		return ret.free + ret.cached
	}

	page_size := u64(os.page_size())
	mut watermark_low := u64(0)

	for line in lines {
		fields := line.split_by_space()
		if fields.len < 2 {
			continue
		}
		if fields[0].starts_with('low') {
			low_value := fields[1].u64()
			watermark_low += low_value
		}
	}
	watermark_low *= page_size

	mut avail_memory := ret.free - watermark_low

	mut page_cache := ret_ex.active_file + ret_ex.inactive_file
	page_cache -= u64(math.min(f64(page_cache / 2), f64(watermark_low)))
	avail_memory += page_cache
	avail_memory += ret.sreclaimable - u64(math.min(f64(ret.sreclaimable / 2), f64(watermark_low)))

	return avail_memory
}

fn parse_swaps_lines(path string, lines []string) ![]SwapDevice {
	if lines.len == 0 {
		return error("unexpected end-of-file in '${path}'")
	}
	header_fields := lines[0].split_by_space()
	if header_fields.len <= used_col {
		return error("couldn't parse '${path}': too few fields in header")
	}
	if header_fields[name_col] != 'Filename' {
		return error("couldn't parse '${path}': expected '${header_fields[name_col]}' to be 'Filename'")
	}
	if header_fields[total_col] != 'Size' {
		return error("couldn't parse '${path}': expected '${header_fields[total_col]}' to be 'Size'")
	}
	if header_fields[used_col] != 'Used' {
		return error("couldn't parse '${path}': expected '${header_fields[used_col]}' to be 'Used'")
	}

	mut devices := []SwapDevice{}
	for i in 1 .. lines.len {
		fields := lines[i].split_by_space()
		if fields.len <= used_col {
			return error("couldn't parse '${path}': too few fields")
		}
		total_kib := fields[total_col].u64()
		used_kib := fields[used_col].u64()
		devices << SwapDevice{
			name:       fields[name_col]
			used_bytes: used_kib * 1024
			free_bytes: (total_kib - used_kib) * 1024
		}
	}
	return devices
}

fn parse_meminfo_u64(value string) !u64 {
	return value.parse_uint(10, 64) or {
		return error('invalid meminfo integer "${value}"')
	}
}

fn parse_kb(value string) !u64 {
	n := parse_meminfo_u64(value)!
	return n * 1024
}

fn meminfo_kb(ctx context.Context, key string) !u64 {
	filename := host_proc(ctx, 'meminfo')
	lines := os.read_lines(filename) or {
		return error("couldn't read ${filename}: ${err}")
	}
	for line in lines {
		parts := line.split(':')
		if parts.len != 2 {
			continue
		}
		if parts[0].trim_space() == key {
			value := parts[1].trim_space().replace(' kB', '')
			return parse_kb(value)!
		}
	}
	return error("key '${key}' not found in ${filename}")
}
