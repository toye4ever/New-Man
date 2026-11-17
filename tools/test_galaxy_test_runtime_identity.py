"""Execute the temporary Application guard with minimal Android API fakes.

This proves the guard's decision/order, not Android lifecycle or APK compilation.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class GalaxyRuntimeIdentityTests(unittest.TestCase):
    def test_actual_guard_rejects_wrong_identity_before_application_start(self):
        java = shutil.which('java')
        if not java:
            self.skipTest('Existing Java runtime/compiler module unavailable')
        root = Path(__file__).resolve().parents[1]
        sources = {
            'android/content/pm/PackageManager.java': 'package android.content.pm; public class PackageManager {}',
            'android/content/pm/ApplicationInfo.java': '''package android.content.pm;
public class ApplicationInfo {
 public static final int FLAG_DEBUGGABLE = 2;
 public int flags = 2;
 public String label = "New Man Test";
 public CharSequence loadLabel(PackageManager ignored) { return label; }
}''',
            'android/app/Application.java': '''package android.app;
import android.content.pm.*;
public class Application {
 public static String name = "com.newman.newmanapp.beta.dev.nov17";
 public static ApplicationInfo info = new ApplicationInfo();
 public static boolean started;
 public String getPackageName() { return name; }
 public ApplicationInfo getApplicationInfo() { return info; }
 public PackageManager getPackageManager() { return new PackageManager(); }
 public void onCreate() { started = true; }
}''',
            'com/newman/newmanapp/IdentityCheck.java': '''package com.newman.newmanapp;
import android.app.Application;
public class IdentityCheck {
 static void run(boolean allowed) {
  Application.started = false;
  try {
   new GalaxyTestApplication().onCreate();
   if (!allowed || !Application.started) throw new AssertionError();
  } catch (IllegalStateException rejected) {
   if (allowed || Application.started) throw new AssertionError();
  }
 }
 public static void main(String[] args) {
  run(true);
  for (String wrong : new String[]{"com.newman.newmanapp.beta", "com.newman.newmanapp.beta.dev", "", "other"}) {
   Application.name = wrong; run(false);
  }
  Application.name = "com.newman.newmanapp.beta.dev.nov17";
  Application.info.flags = 0; run(false);
  Application.info.flags = 2;
  for (String wrong : new String[]{"New Man Dev", "New Man Beta", ""}) {
   Application.info.label = wrong; run(false);
  }
  Application.info.label = "New Man Test"; run(true);
 }
}''',
        }
        with tempfile.TemporaryDirectory(prefix='new-man-identity-') as temporary:
            directory = Path(temporary)
            files = []
            for name, body in sources.items():
                path = directory / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(body)
                files.append(str(path))
            files.append(str(root / 'android/app/src/debug/java/com/newman/newmanapp/GalaxyTestApplication.java'))
            subprocess.run([java, '-m', 'jdk.compiler/com.sun.tools.javac.Main', '-d', temporary, *files], check=True, capture_output=True, timeout=30)
            subprocess.run([java, '-cp', temporary, 'com.newman.newmanapp.IdentityCheck'], check=True, capture_output=True, timeout=10)
