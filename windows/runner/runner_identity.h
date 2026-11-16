#ifndef NEW_MAN_RUNNER_IDENTITY_H_
#define NEW_MAN_RUNNER_IDENTITY_H_

// path_provider_windows derives app support (including preferences) from the
// executable's CompanyName/ProductName. Never change the release identity to
// isolate tests, and never migrate/copy the old shared directory into Debug.
#ifdef _DEBUG
#define NEW_MAN_PRODUCT_NAME "New Man Dev"
#define NEW_MAN_WINDOW_TITLE L"New Man Dev"
#else
#define NEW_MAN_PRODUCT_NAME "New Man"
#define NEW_MAN_WINDOW_TITLE L"New Man"
#endif

#endif  // NEW_MAN_RUNNER_IDENTITY_H_
