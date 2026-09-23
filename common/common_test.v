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

module common

import context

fn test_with_env_overrides_getenv() {
	mut em := EnvMap{}
	em[host_proc_env_key] = '/myproc'
	ctx := with_env(context.background(), em)
	assert getenv(ctx, host_proc_env_key) == '/myproc'
}

fn test_getenv_falls_back_to_os() {
	ctx := context.background()
	_ = getenv(ctx, host_proc_env_key)
}
