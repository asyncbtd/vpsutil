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

#flag windows -lpsapi -lpdh

#insert "mem_windows.h"

@[typedef]
pub struct C.VpsutilPageFile {
	name       [260]u16
	used_bytes u64
	free_bytes u64
}

@[typedef]
pub struct C.VpsutilPageFileList {
	items     [32]C.VpsutilPageFile
	count     int
	page_size u64
}

fn C.vpsutil_collect_page_files(out &C.VpsutilPageFileList) int

fn C.vpsutil_paging_file_usage_percent(pct &f64) int
