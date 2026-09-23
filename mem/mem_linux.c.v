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

#insert "mem_linux.h"

fn C.vpsutil_linux_swap_bytes(total &u64, free &u64) int

pub fn vpsutil_linux_swap_bytes(total &u64, free &u64) int {
	return C.vpsutil_linux_swap_bytes(total, free)
}
