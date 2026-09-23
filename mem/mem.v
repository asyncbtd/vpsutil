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

import json2
import context

struct VirtualMemoryStat {
mut:
	total            u64 @[json: 'total']
	available        u64 @[json: 'available']
	used             u64 @[json: 'used']
	used_percent     f64 @[json: 'used_percent']
	free             u64 @[json: 'free']
	active           u64 @[json: 'active']
	inactive         u64 @[json: 'inactive']
	wired            u64 @[json: 'wired']
	laundry          u64 @[json: 'laundry']
	buffers          u64 @[json: 'buffers']
	cached           u64 @[json: 'cached']
	dirty            u64 @[json: 'dirty']
	shared           u64 @[json: 'shared']
	slab             u64 @[json: 'slab']
	sreclaimable     u64 @[json: 'sreclaimable']
	sunreclaim       u64 @[json: 'sunreclaim']
	page_tables      u64 @[json: 'page_tables']
	mapped           u64 @[json: 'mapped']
	write_back       u64 @[json: 'write_back']
	write_back_tmp   u64 @[json: 'write_back_tmp']
	commit_limit     u64 @[json: 'commit_limit']
	committed_as     u64 @[json: 'committed_as']
	high_total       u64 @[json: 'high_total']
	high_free        u64 @[json: 'high_free']
	low_total        u64 @[json: 'low_total']
	low_free         u64 @[json: 'low_free']
	swap_total       u64 @[json: 'swap_total']
	swap_free        u64 @[json: 'swap_free']
	swap_cached      u64 @[json: 'swap_cached']
	vmalloc_total    u64 @[json: 'vmalloc_total']
	vmalloc_used     u64 @[json: 'vmalloc_used']
	vmalloc_chunk    u64 @[json: 'vmalloc_chunk']
	huge_pages_total u64 @[json: 'huge_pages_total']
	huge_pages_free  u64 @[json: 'huge_pages_free']
	huge_pages_rsvd  u64 @[json: 'huge_pages_rsvd']
	huge_pages_surp  u64 @[json: 'huge_pages_surp']
	huge_page_size   u64 @[json: 'huge_page_size']
	anon_huge_pages  u64 @[json: 'anon_huge_pages']
}

struct SwapDevice {
	name       string @[json: 'name']
	used_bytes u64    @[json: 'used_bytes']
	free_bytes u64    @[json: 'free_bytes']
}

struct SwapMemoryStat {
mut:
	total        u64 @[json: 'total']
	used         u64 @[json: 'used']
	free         u64 @[json: 'free']
	used_percent f64 @[json: 'used_percent']
	sin          u64 @[json: 'sin']
	sout         u64 @[json: 'sout']
	pg_in        u64 @[json: 'pg_in']
	pg_out       u64 @[json: 'pg_out']
	pg_fault     u64 @[json: 'pg_fault']
	pg_maj_fault u64 @[json: 'pg_maj_fault']
}

// str returns a JSON representation of the virtual memory stats.
pub fn (m &VirtualMemoryStat) str() string {
	return json2.encode(m)
}

// str returns a JSON representation of the swap device.
pub fn (m &SwapDevice) str() string {
	return json2.encode(m)
}

// str returns a JSON representation of the swap memory stats.
pub fn (m &SwapMemoryStat) str() string {
	return json2.encode(m)
}

// virtual_memory reports system virtual memory statistics.
pub fn virtual_memory() !VirtualMemoryStat {
	return virtual_memory_with_context(context.background())!
}

// swap_memory reports system swap memory statistics.
pub fn swap_memory() !SwapMemoryStat {
	return swap_memory_with_context(context.background())!
}

// swap_devices lists per-device swap usage.
pub fn swap_devices() ![]SwapDevice {
	return swap_devices_with_context(context.background())!
}
