import UIKit
import Flutter
import BackgroundTasks
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Register BG refresh task (identifier MUST match Info.plist)
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.app.refresh", using: nil) { task in
      self.handleAppRefresh(task: task as! BGAppRefreshTask)
    }

    // Schedule a refresh hint
    scheduleAppRefresh()

    // Make sure Flutter plugins (e.g., home_widget) are registered
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func scheduleAppRefresh() {
    let req = BGAppRefreshTaskRequest(identifier: "com.example.app.refresh")
    req.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 60 * 60) // ~6h hint
    do {
      try BGTaskScheduler.shared.submit(req)
    } catch {
      print("BG submit error: \(error)")
      // If you see BGTaskSchedulerErrorDomain Code=1 here:
      // - Use a real device
      // - Check Info.plist identifier
      // - Enable Background fetch capability
      // - Ensure Background App Refresh is ON on the device
    }
  }

  func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefresh() // always reschedule the next one

    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }

    // Do your lightweight fetch, save into App Group, then reload widget timelines
    fetchAndSavePrayerTimes { ok in
      WidgetCenter.shared.reloadTimelines(ofKind: "MyHomeWidget")
      task.setTaskCompleted(success: ok)
    }
  }

  private func fetchAndSavePrayerTimes(completion: @escaping (Bool) -> Void) {
    let address = "Sydney NSW, Australia"
    var comps = URLComponents(string: "https://apis.sadaqawelfarefund.ngo/api/get_prayer_times")!
    comps.queryItems = [URLQueryItem(name: "address", value: address)]
    let url = comps.url!

    let t = URLSession.shared.dataTask(with: url) { data, resp, err in
      guard err == nil, let data = data,
            let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        return completion(false)
      }
      guard let any = try? JSONSerialization.jsonObject(with: data),
            let list = (any as? [Any]) ??
                       ((any as? [String:Any])?["data"] as? [Any]) ??
                       ((any as? [String:Any])?["days"] as? [Any]) ??
                       ((any as? [String:Any])?["prayer_times"] as? [Any]),
            let chosen = (list.first { ($0 as? [String:Any])?["is_current_day"] as? Bool == true } ?? list.first) as? [String:Any]
      else { return completion(false) }

      func pick(_ k: String) -> String { (chosen[k] as? CustomStringConvertible)?.description ?? "" }

      let ud = UserDefaults(suiteName: "group.homeTestScreenApp")
      ud?.set(pick("fajr"), forKey: "fajr")
      ud?.set(pick("dhuhr").isEmpty ? pick("Dhuhr") : pick("dhuhr"), forKey: "dhuhr")
      ud?.set(pick("asr"), forKey: "asr")
      ud?.set(pick("maghrib"), forKey: "maghrib")
      ud?.set(pick("isha"), forKey: "isha")
      ud?.set(pick("sunrise"), forKey: "sunrise")
      ud?.set(pick("hijri_date"), forKey: "hijri_date")
      ud?.set(pick("hijri_month"), forKey: "hijri_month")
      ud?.set("Sadaqa Welfare Fund", forKey: "company_name")

      let now = Date()
      let hh = String(format: "%02d", Calendar.current.component(.hour, from: now))
      let mm = String(format: "%02d", Calendar.current.component(.minute, from: now))
      ud?.set("\(hh):\(mm)", forKey: "last_updated")

      completion(true)
    }
    t.resume()
  }
}
