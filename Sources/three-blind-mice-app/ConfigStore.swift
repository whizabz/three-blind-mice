import Foundation

struct ConfigStore {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadOrCreateDefault() throws -> AppConfig {
        let path = try configFilePath()
        guard fileManager.fileExists(atPath: path.path) else {
            let defaultConfig = AppConfig.default
            try save(defaultConfig)
            return defaultConfig
        }
        let data = try Data(contentsOf: path)
        return try decoder.decode(AppConfig.self, from: data)
    }

    func save(_ config: AppConfig) throws {
        let path = try configFilePath()
        try fileManager.createDirectory(
            at: path.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(config)
        try data.write(to: path, options: .atomic)
    }

    func configFilePath() throws -> URL {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ConfigStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Application Support directory unavailable"])
        }
        return appSupport
            .appendingPathComponent("three-blind-mice", isDirectory: true)
            .appendingPathComponent("config.json", isDirectory: false)
    }
}
