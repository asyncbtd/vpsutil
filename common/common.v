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
import os

pub type EnvKeyType = string

pub const env_key = EnvKeyType('env')

pub const host_proc_env_key = EnvKeyType('HOST_PROC')

pub type EnvMap = map[EnvKeyType]string

pub fn getenv(ctx context.Context, key EnvKeyType) string {
	em := env_from_context(ctx) or {
		return os.getenv(key)
	}
	v := em[key]
	if v != '' {
		return v
	}
	return os.getenv(key)
}

pub fn with_env(parent context.Context, env EnvMap) context.Context {
	return context.with_value(parent, env_key, env)
}

pub fn env_from_context(ctx context.Context) ?EnvMap {
	val := ctx.value(env_key) or {
		return none
	}
	if val is EnvMap {
		return val as EnvMap
	}
	return none
}
