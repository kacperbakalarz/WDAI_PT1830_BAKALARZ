import SwiftUI
import AVFoundation
import Playgrounds
import Combine

struct ContentView: View {
    @State private var birdY: CGFloat = 200
    @State private var birdX: CGFloat = 200
    @State private var velocity: CGFloat = 0
    @State private var isGameOver = false
    @State private var isGameStarted = false
    @State private var pipeGapY: CGFloat = 300
    @State private var pipeX: CGFloat = 500
    @State private var counter: Int = 0
    @State private var hasScoredCurrentPipe = false
    @State private var currentBirdImage = "yellowbird-midflap"
    @State private var currentBG = "background-day"
    @State private var startScreen = true
    @State private var leaderboard: [Int] = []
    
    let pipeWidth: CGFloat = 60
    let pipeGapHeight: CGFloat = 170
    let pipeSpeed: CGFloat = 6.0
    let baseHeight: CGFloat = 112
    
    let gravity: CGFloat = 0.35
    let jumpForce: CGFloat = -7.0
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    func resetGame(screenWidth: CGFloat, screenHeight: CGFloat) {
        isGameOver = false
        birdY = screenHeight * 0.4
        velocity = 0
        isGameStarted = false
        counter = 0
        hasScoredCurrentPipe = false
        pipeX = screenWidth + pipeWidth
        pipeGapY = screenHeight * 0.45
        if currentBG == "background-day"{
            currentBG = "background-night"
        }
        else{
            currentBG = "background-day"
        }
        
    }
    
    @State private var players: [AVAudioPlayer] = []

    func playSound(_ soundName: String, ext: String = "wav") {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: ext) else {
            print("Nie znaleziono pliku: \(soundName).\(ext)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
   
            players.removeAll { !$0.isPlaying }
            players.append(player)
        } catch {
            print("Błąd odtwarzania dźwięku: \(error.localizedDescription)")
        }
    }
    func startGame(screenWidth: CGFloat, screenHeight: CGFloat){
        startScreen = false
    }
    
    var body: some View {
        GeometryReader { geo in
            let minDimension = min(geo.size.width, geo.size.height)
            let birdWidth = minDimension * 0.08
            let birdHeight = birdWidth * (24.0 / 34.0)
            
            ZStack {
                //background
                Image(currentBG)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                VStack {
                    HStack(spacing: 4) {
                        ForEach(Array(String(counter).enumerated()), id: \.offset) { _, digit in
                            Image(String(digit))
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 45)
                        }
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                }
                if startScreen{
                    VStack(spacing: -200) {
                        Image("Image")
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220)
                        
                        Button("start") {
                            startScreen = false
                            isGameStarted = true
                        }
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                    }
                }
                //pipe
                VStack(spacing: pipeGapHeight) {
                    Image("pipe-green")
                        .interpolation(.none)
                        .resizable()
                        .frame(width: pipeWidth, height: 600)
                        .rotationEffect(.degrees(180))
                    
                    Image("pipe-green")
                        .interpolation(.none)
                        .resizable()
                        .frame(width: pipeWidth, height: 600)
                }
                .position(x: pipeX, y: pipeGapY)
                //floor
                VStack {
                    Spacer()
                    Image("base")
                        .interpolation(.none)
                        .resizable()
                        .frame(width: geo.size.width, height: baseHeight)
                }
                //roof
                VStack {
                    Spacer()
                    
                }
                Image(currentBirdImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: birdWidth, height: birdHeight)
                    .position(x: birdX, y: birdY)
                
                
                if isGameOver {
                    VStack(spacing: 30) {
                        Image("gameover")
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220)
                        
                        Button("Play again") {
                            resetGame(screenWidth: geo.size.width, screenHeight: geo.size.height)
                        }
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        VStack(spacing: 0){
                            ForEach(Array(leaderboard.prefix(5).enumerated()), id: \.offset) { index, element in
                                Text("#\(index+1): \(element)" )
                            }
                            .font(.headline)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 5)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            
                        }
                        
                    }
                }
            }
            .contentShape(Rectangle())
            .focusable()
            .onAppear {
                pipeX = geo.size.width + pipeWidth
                pipeGapY = geo.size.height * 0.45
                birdY = geo.size.height * 0.4

            }
            .onKeyPress(.return) {
                startScreen = false
                playSound("wing")
                if !isGameOver {
                    isGameStarted = true
                    velocity = jumpForce
                } else {
                    resetGame(screenWidth: geo.size.width, screenHeight: geo.size.height)
                }
                return .handled
            }
            .onReceive(timer) { _ in
                guard isGameStarted && !isGameOver else { return }
                
                let floorY = geo.size.height - baseHeight - (birdHeight / 2)
                    
                let ceilingY = birdHeight / 2
                
                velocity += gravity
                birdY += velocity
                
                //ground collision
                if birdY >= floorY {
                    playSound("die")
                    birdY = floorY
                    velocity = 0
                    leaderboard.append(counter)
                    leaderboard.sort(by: >)
                    isGameOver = true
                }
                if birdY <= ceilingY{
                    birdY = ceilingY
                    velocity = 0
                }
                if velocity > 0 {
                    currentBirdImage = "yellowbird-upflap"
                }
                if velocity < 0 {
                    currentBirdImage = "yellowbird-downflap"
                }
                if velocity == 0 {
                    currentBirdImage = "yellowbird-midflap"
                }
                
                let hitPipeX = (birdX + birdWidth / 2 > pipeX - pipeWidth / 2) &&
                              (birdX - birdWidth / 2 < pipeX + pipeWidth / 2)
                
                let hitTopPipe = (birdY - birdHeight / 2) < (pipeGapY-pipeGapHeight / 2)
                
                let hitBottomPipe = (birdY + birdHeight / 2) > (pipeGapY+pipeGapHeight / 2)
               
                _ = (birdY - birdHeight / 2) == (pipeGapY-pipeGapHeight / 2) && (birdY + birdHeight / 2) == (pipeGapY+pipeGapHeight / 2)
                
                //bottom pipe collision
                if hitPipeX && hitTopPipe{
                    playSound("hit")
                    playSound("die")
                    velocity = 0
                    leaderboard.append(counter)
                    leaderboard.sort(by: >)
                    isGameOver = true
                    
                }
                
                //upper pipe collision
                if hitPipeX && hitBottomPipe{
                    playSound("hit")
                    playSound("die")
                    velocity = 0
                    leaderboard.append(counter)
                    leaderboard.sort(by: >)
                    isGameOver = true
                    
                }
                //counter
                let previousPipeX = pipeX
                pipeX -= pipeSpeed
                
                if previousPipeX > birdX && pipeX <= birdX {
                    counter += 1
                    playSound("point")
                }
                
                if pipeX < -pipeWidth {
                    pipeX = geo.size.width + pipeWidth
                    let minGapY = pipeGapHeight / 2 + 60
                    let maxGapY = geo.size.height - baseHeight - pipeGapHeight / 2 - 60
                    if maxGapY > minGapY {
                        pipeGapY = CGFloat.random(in: minGapY...maxGapY)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
