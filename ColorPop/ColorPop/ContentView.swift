import SwiftUI


//data model being returned by API
struct ColorPalette: Codable, Identifiable {
    //codable allows it to be encoded/decoded by JSON
    let id = UUID()
    let colors: [String]

    enum CodingKeys: String, CodingKey {
        case colors
    }
}

class ColorAPI {
    //static method that takes in the textfield user input and creates a colorpalette array
    static func fetchPalettes(query: String) async throws -> [ColorPalette] {
        guard let url = URL(string: "https://colormagic.app/api/palette/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode([ColorPalette].self, from: data)
        return decoded
    }
}


struct ContentView: View {
    @State private var searchText = "" //input string of color pallete you want to create
    @State private var palettes: [ColorPalette] = [] //array of individual color palettes
    @State private var selectedColor: String? = nil //color clicked on

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                //COLORPOP logo from canva inserted
                Image("COLORPOP")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 150)
                
                //purple design feature
                Rectangle()
                    .fill(Color(red: 75/255, green: 0/255, blue: 130/255))
                    .frame(width: 1000, height: 25)
                    .cornerRadius(4)
                
                //textfield for user input
                HStack {
                    TextField("Enter a word like 'sunset'...", text: $searchText)
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 75/255, green: 0/255, blue: 130/255), lineWidth: 2)
                        )
                        .cornerRadius(10)
                        .shadow(color: .gray.opacity(0.4), radius: 3, x: 0, y: 2)
                    
                //when the "Go" button is clicked it calls the "fetchedPalettes" from the "ColorAPI" static method
                Button("Go") {
                        Task {
                            do {
                                let fetchedPalettes = try await ColorAPI.fetchPalettes(query: searchText)
                                self.palettes = fetchedPalettes
                            } catch {
                                print("Failed to fetch palettes: \(error)")
                            }
                        }
                    }
                }
                .padding()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(palettes) { palette in
                            PaletteCard(palette: palette, selectedColor: $selectedColor)
                        }
                    }
                    .padding()
                }

                if let hex = selectedColor {
                    Text("You selected: \(hex)")
                        .padding()
                        .background(Color(hex: hex))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("")
        }
    }
}

//builds the color paletter based off the generated palette
struct PaletteCard: View {
    let palette: ColorPalette
    @Binding var selectedColor: String?

    var body: some View {
        HStack {
            ForEach(palette.colors, id: \.self) { hex in
                NavigationLink(destination: ColorDetailView(hex: hex)) {
                    Rectangle()
                        .fill(Color(hex: hex))
                        .frame(width: 40, height: 40)
                        .cornerRadius(6)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    selectedColor = hex
                })
            }
        }
    }
}

// view once a color block has been clicked on
struct ColorDetailView: View {
    let hex: String

    var body: some View {
        ZStack {
            Color(hex: hex)
                .ignoresSafeArea()

            Text(hex)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
        .navigationTitle("Color Detail")
    }
}

//generates a color based off of a hex string (returned from the API)
extension Color {
    init(hex: String) {
        let cleanedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let scanner = Scanner(string: cleanedHex)
        var int: UInt64 = 0

        if scanner.scanHexInt64(&int) {
            let r = Double((int >> 16) & 0xFF) / 255.0
            let g = Double((int >> 8) & 0xFF) / 255.0
            let b = Double(int & 0xFF) / 255.0
            self.init(red: r, green: g, blue: b)
        } else {
            self.init(.gray) // fallback color
        }
    }
}

#Preview {
    ContentView()
}


