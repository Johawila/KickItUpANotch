//
//  SystemStatsMonitor.swift
//  KickItUpANotch
//
//  Created by Johan Wilander on 2026-03-10.
//

import Foundation
import IOKit.ps
import Darwin
import Observation

@Observable
final class SystemStatsMonitor {
    var cpuUsage: Double = 0
    var ramUsage: Double = 0
    var batteryLevel: Double = 0
    var isCharging: Bool = false

    private var previousTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32) = (0, 0, 0, 0)
    private var timer: Timer?

    init() {
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    deinit { timer?.invalidate() }

    private func update() {
        updateCPU()
        updateRAM()
        updateBattery()
    }

    // MARK: - CPU

    private func updateCPU() {
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let kr = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return }

        let user   = cpuLoad.cpu_ticks.0 - previousTicks.user
        let system = cpuLoad.cpu_ticks.1 - previousTicks.system
        let idle   = cpuLoad.cpu_ticks.2 - previousTicks.idle
        let nice   = cpuLoad.cpu_ticks.3 - previousTicks.nice
        let total  = user + system + idle + nice

        if total > 0 {
            cpuUsage = Double(user + system + nice) / Double(total)
        }

        previousTicks = (cpuLoad.cpu_ticks.0, cpuLoad.cpu_ticks.1, cpuLoad.cpu_ticks.2, cpuLoad.cpu_ticks.3)
    }

    // MARK: - RAM

    private func updateRAM() {
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let kr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)
        let used     = (UInt64(vmStats.active_count)
                      + UInt64(vmStats.wire_count)
                      + UInt64(vmStats.compressor_page_count)) * pageSize
        let total    = UInt64(ProcessInfo.processInfo.physicalMemory)

        ramUsage = Double(used) / Double(total)
    }

    // MARK: - Battery

    private func updateBattery() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources  = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)
                    .takeUnretainedValue() as? [String: Any] else { continue }
            if let capacity = info[kIOPSCurrentCapacityKey] as? Int,
               let max      = info[kIOPSMaxCapacityKey] as? Int, max > 0 {
                batteryLevel = Double(capacity) / Double(max)
                isCharging   = (info[kIOPSIsChargingKey] as? Bool) ?? false
            }
        }
    }

}
