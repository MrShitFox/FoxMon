# FoxMon

**FoxMon** is an open-source system monitoring daemon written in Go (version **1.13** or higher). It monitors CPU usage, memory usage, and network traffic (incoming/outgoing) on a server and provides this information via a POST request to an endpoint.

## Features

- **CPU Monitoring:** Real-time CPU usage statistics.
- **Memory Monitoring:** Reports used and total memory.
- **Network Traffic Monitoring:** Monitors incoming and outgoing network traffic.
- **RESTful API Endpoint:** Provides system status via a POST request to `/status`.
- **Lightweight and Efficient:** Minimal resource usage.
- **Cross-Platform:** Works on Linux, macOS, and Windows.

## How It Works

FoxMon runs as a daemon and collects system metrics every second. It maintains the current system status in memory. When a POST request is made to the `/status` endpoint (e.g., `http://192.168.1.2:60100/status`), it returns the latest collected system metrics in JSON format.

## Installation

### Prerequisites

- **Go 1.13** or higher installed on your system.

### Download and Build

1. **Clone the Repository**

   ```sh
   git clone https://github.com/YourUsername/FoxMon.git
   cd FoxMon
   ```

2. **Initialize the Go Module**

   ```sh
   go mod init FoxMon
   ```

3. **Install Dependencies**

   ```sh
   go get github.com/shirou/gopsutil/v3/...
   ```

4. **Build the Application**

   ```sh
   go build -o foxmon main.go
   ```

## Usage

### Running FoxMon

1. **Execute the Binary**

   ```sh
   ./foxmon
   ```

   The server will start and listen on port `60100`.

2. **Verify the Server is Running**

   Check the console output:

   ```
   Server started on port :60100
   ```

### Accessing System Status

To retrieve the current system status, send a POST request to the `/status` endpoint.

**Example using `curl`:**

```sh
curl -X POST http://localhost:60100/status
```

**Sample Response:**

```json
{
  "cpu_usage": 15.2,
  "memory_used": 4096000000,
  "memory_total": 8192000000,
  "network_in": 1024,
  "network_out": 2048
}
```

If you're accessing the service from another machine on the network, replace `localhost` with the server's IP address (e.g., `192.168.1.2`).

### Running FoxMon in the Background

To run FoxMon as a daemon in the background, you can use tools like `nohup`, `screen`, or create a systemd service file.

**Example using `nohup`:**

```sh
nohup ./foxmon &
```

## Contributing

Contributions are welcome! If you'd like to contribute to FoxMon:

1. **Fork** the repository.
2. **Create** a new branch for your feature or bug fix.
3. **Commit** your changes with clear messages.
4. **Push** your branch to your fork.
5. **Submit** a pull request.

Please ensure your contributions adhere to the project's coding standards and include necessary tests.

## License

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the need for simple and efficient system monitoring tools.

## Disclaimer

**FoxMon** is intended for personal and professional use. Please ensure you comply with your organization's policies when deploying monitoring tools. The authors are not responsible for any misuse or violations of any policies.

---

### Additional Notes

- **Port Configuration:** If you need the server to listen on a specific IP address (e.g., `192.168.1.2`), modify the `ListenAndServe` call in `main.go`:

  ```go
  http.ListenAndServe("192.168.1.2:60100", nil)
  ```

- **Building for Different Platforms:** You can cross-compile FoxMon for different operating systems using Go's build flags.

  **Example:**

  ```sh
  # Build for Windows
  GOOS=windows GOARCH=amd64 go build -o foxmon.exe main.go

  # Build for Linux
  GOOS=linux GOARCH=amd64 go build -o foxmon main.go
  ```

- **Logging:** The application logs errors and status messages to the console. Consider redirecting output to a log file when running as a daemon.

  **Example using `nohup`:**

  ```sh
  nohup ./foxmon > foxmon.log 2>&1 &
  ```
