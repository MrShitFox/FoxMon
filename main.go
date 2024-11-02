package main

import (
    "encoding/json"
    "log"
    "net/http"
    "sync"
    "time"

    "github.com/shirou/gopsutil/v3/cpu"
    "github.com/shirou/gopsutil/v3/mem"
    "github.com/shirou/gopsutil/v3/net"
)

type SystemStatus struct {
    CPUUsage    float64 `json:"cpu_usage"`
    MemoryUsed  uint64  `json:"memory_used"`
    MemoryTotal uint64  `json:"memory_total"`
    NetworkIn   uint64  `json:"network_in"`
    NetworkOut  uint64  `json:"network_out"`
}

var (
    currentStatus *SystemStatus
    statusMutex   sync.RWMutex
)

func collectSystemStatus() {
    var prevNetIOCounters map[string]net.IOCountersStat

    for {
        status, newPrevNetIOCounters, err := getSystemStatus(prevNetIOCounters)
        if err != nil {
            log.Println("Error collecting system status:", err)
        } else {
            statusMutex.Lock()
            currentStatus = status
            statusMutex.Unlock()
            prevNetIOCounters = newPrevNetIOCounters
        }
        time.Sleep(1 * time.Second)
    }
}

func getSystemStatus(prevNetIOCounters map[string]net.IOCountersStat) (*SystemStatus, map[string]net.IOCountersStat, error) {
    cpuPercentages, err := cpu.Percent(0, false)
    if err != nil {
        return nil, prevNetIOCounters, err
    }
    cpuUsage := cpuPercentages[0]

    vmStat, err := mem.VirtualMemory()
    if err != nil {
        return nil, prevNetIOCounters, err
    }

    netIOCounters, err := net.IOCounters(true)
    if err != nil {
        return nil, prevNetIOCounters, err
    }

    currentNetIOCounters := make(map[string]net.IOCountersStat)
    var networkIn, networkOut uint64

    if len(prevNetIOCounters) == 0 {
        for _, counter := range netIOCounters {
            currentNetIOCounters[counter.Name] = counter
        }
        networkIn = 0
        networkOut = 0
    } else {
        for _, counter := range netIOCounters {
            currentNetIOCounters[counter.Name] = counter
            if prev, ok := prevNetIOCounters[counter.Name]; ok {
                networkIn += counter.BytesRecv - prev.BytesRecv
                networkOut += counter.BytesSent - prev.BytesSent
            }
        }
    }

    return &SystemStatus{
        CPUUsage:    cpuUsage,
        MemoryUsed:  vmStat.Used,
        MemoryTotal: vmStat.Total,
        NetworkIn:   networkIn,
        NetworkOut:  networkOut,
    }, currentNetIOCounters, nil
}

func statusHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "Only POST method is supported", http.StatusMethodNotAllowed)
        return
    }

    statusMutex.RLock()
    defer statusMutex.RUnlock()

    if currentStatus == nil {
        http.Error(w, "Data not yet collected", http.StatusServiceUnavailable)
        return
    }

    jsonResponse, err := json.Marshal(currentStatus)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    w.Write(jsonResponse)
}

func main() {
    go collectSystemStatus()

    http.HandleFunc("/status", statusHandler)

    log.Println("Server started on port :60100")
    if err := http.ListenAndServe(":60100", nil); err != nil {
        log.Fatal(err)
    }
}
