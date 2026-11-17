package com.newman.newmanapp;

import android.app.Application;
import android.content.pm.ApplicationInfo;

/** Only selected by the fixed, opt-in temporary Galaxy Debug build. */
public final class GalaxyTestApplication extends Application {
    static void requireIdentity(String packageName, boolean debuggable, String label) {
        if (!"com.newman.newmanapp.beta.dev.nov17".equals(packageName)
                || !debuggable || !"New Man Test".equals(label)) {
            throw new IllegalStateException("Temporary test installation identity mismatch");
        }
    }

    @Override public void onCreate() {
        requireIdentity(getPackageName(),
                (getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0,
                getApplicationInfo().loadLabel(getPackageManager()).toString());
        super.onCreate();
    }
}
