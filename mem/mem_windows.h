/*
 * Copyright 2026 Timofey Brukhanchik (asyncbtd)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <windows.h>
#include <psapi.h>
#include <pdh.h>

#define VPSUTIL_MAX_PAGE_FILES 32

typedef struct {
	wchar_t name[MAX_PATH];
	unsigned long long used_bytes;
	unsigned long long free_bytes;
} VpsutilPageFile;

typedef struct {
	VpsutilPageFile items[VPSUTIL_MAX_PAGE_FILES];
	int count;
	unsigned long long page_size;
} VpsutilPageFileList;

typedef struct _VPSUTIL_ENUM_PAGE_FILE_INFORMATION {
	DWORD cb;
	DWORD Reserved;
	SIZE_T TotalSize;
	SIZE_T TotalInUse;
	SIZE_T PeakUsage;
} VpsutilEnumPageFileInformation;

static BOOL CALLBACK vpsutil_enum_page_file_cb(PVOID pContext, PVOID pPageFileInfo, LPCWSTR pPageFileName) {
	VpsutilPageFileList *list = (VpsutilPageFileList *)pContext;
	VpsutilEnumPageFileInformation *info = (VpsutilEnumPageFileInformation *)pPageFileInfo;
	if (list->count >= VPSUTIL_MAX_PAGE_FILES) {
		return TRUE;
	}
	VpsutilPageFile *pf = &list->items[list->count];
	if (pPageFileName != NULL) {
		wcsncpy(pf->name, pPageFileName, MAX_PATH);
		pf->name[MAX_PATH - 1] = L'\0';
	}
	unsigned long long ps = list->page_size;
	pf->used_bytes = (unsigned long long)info->TotalInUse * ps;
	pf->free_bytes = ((unsigned long long)info->TotalSize - (unsigned long long)info->TotalInUse) * ps;
	list->count++;
	return TRUE;
}

int vpsutil_collect_page_files(VpsutilPageFileList *out) {
	SYSTEM_INFO si;
	GetNativeSystemInfo(&si);
	out->page_size = (unsigned long long)si.dwPageSize;
	out->count = 0;
	if (!EnumPageFilesW(vpsutil_enum_page_file_cb, out)) {
		return 0;
	}
	return 1;
}

int vpsutil_paging_file_usage_percent(double *pct) {
	PDH_HQUERY query = NULL;
	PDH_HCOUNTER counter = NULL;
	PDH_FMT_COUNTERVALUE value;
	if (PdhOpenQuery(NULL, 0, &query) != ERROR_SUCCESS) {
		return 0;
	}
	if (PdhAddEnglishCounterW(query, L"\\Paging File(_Total)\\% Usage", 0, &counter) != ERROR_SUCCESS) {
		PdhCloseQuery(query);
		return 0;
	}
	if (PdhCollectQueryData(query) != ERROR_SUCCESS) {
		PdhCloseQuery(query);
		return 0;
	}
	if (PdhGetFormattedCounterValue(counter, PDH_FMT_DOUBLE, NULL, &value) != ERROR_SUCCESS) {
		PdhCloseQuery(query);
		return 0;
	}
	*pct = value.doubleValue;
	PdhCloseQuery(query);
	return 1;
}
