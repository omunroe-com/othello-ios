//
//  OthelloView.swift
//  othello
//
//  Created by Tetsuwo OISHI on 2017/05/24.
//  Copyright © 2017年 toishitech. All rights reserved.
//

import UIKit

let EMPTY = 0, BLACK_STONE = 1, WHITE_STONE = 2

let initboard = [
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,2,1,0,0,0,0],
    [0,0,0,0,1,2,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
];

class OthelloView: UIView {
    
    var board:[[Int]]
    var side:CGFloat
    var top:CGFloat
    let left:CGFloat = 0
    
    let white = UIColor.whiteColor().CGColor
    let black = UIColor.blackColor().CGColor
    let green = UIColor(red: 0.6, green: 1, blue: 0.2, alpha: 1).CGColor
    
    required init?(coder aDecoder: NSCoder) {
        board = initboard
        let appFrame = UIScreen.mainScreen().bounds
        side = appFrame.size.width / 8
        top = (appFrame.size.height - (side * 8)) / 2
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, white)
        CGContextSetLineWidth(context, 1.5)
        
        for y in 1...8 {
            for x in 1...8 {
                let rx = left + side * CGFloat(x - 1)
                let ry = top + side * CGFloat(y - 1)
                let rect = CGRectMake(rx, ry, side, side)
                CGContextSetFillColorWithColor(context, green)
                CGContextFillRect(context, rect)
                CGContextStrokeRect(context, rect)
                
                if (board[y][x] == BLACK_STONE) {
                    CGContextSetFillColorWithColor(context, black)
                    CGContextFillEllipseInRect(context, rect)
                } else if board[y][x] == WHITE_STONE {
                    CGContextSetFillColorWithColor(context, white)
                    CGContextFillEllipseInRect(context, rect)
                }
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        if let (x, y) = getPosition(touches) {
//            board[y][x] = BLACK_STONE
//        }
        // まずはプレイヤー(黒)が石を置けるか調べる
        if let _ = canPlaced(board, stone: BLACK_STONE) {
            // 選択したマスのxy座標を取り出す
            if let (x, y) = getPosition(touches) {
                // ひっくり返せるか調べる
                if let blackPlaces = flip(board, x: x, y: y, stone: BLACK_STONE) {
                    // 実際にひっくり返す
                    putStones(blackPlaces, stone: BLACK_STONE)
                    // CPU(白)のターンを進める
                    if let whitePlaces = cpuFlip(board, stone: WHITE_STONE) {
                        putStones(whitePlaces, stone: WHITE_STONE)
                    }
                }
            }
        } else {
            // プレイヤーが石を置けないのでスキップしてCPUのターンを進める
            if let whitePlaces = cpuFlip(board, stone: WHITE_STONE) {
                putStones(whitePlaces, stone: WHITE_STONE)
            }
        }
        updateGame()
        setNeedsDisplay()
    }
    
    func updateGame() {
        let (free, black, white) = calcStones(board)
        let canBlack = canPlaced(board, stone: BLACK_STONE)
        let canWhite = canPlaced(board, stone: WHITE_STONE)
        if free == 0 || (canBlack == nil && canWhite == nil) {
            // 空きマスが無い、または黒も白も置けない場合はゲーム終了
            print("Game Over (Black:\(black) White:\(white))")
        }
    }
    
    func getPosition(touches: Set<UITouch>) -> (Int, Int)? {
        let touch = touches.first
        let point = touch!.locationInView(self)
        for y in 1...8 {
            for x in 1...8 {
                let rx = left + side * CGFloat(x - 1)
                let ry = top + side * CGFloat(y - 1)
                let rect = CGRectMake(rx, ry, side, side)
                if (CGRectContainsPoint(rect, point)) {
                    return (x, y)
                }
            }
        }
        
        return nil
    }
    
    func canPlaced(board:[[Int]], stone: Int) -> [(Int, Int)]? {
        var result:[(Int, Int)] = []
        for y in 1...8 {
            for x in 1...8 {
                if let _ = flip(board, x: x, y: y, stone: stone) {
                    result += [(x, y)]
                }
            }
        }
        if result.isEmpty {
            return nil
        } else {
            return result
        }
    }
    
    func getRandomNumber(cnt:Int) -> Int{
        var result:Int
        result = Int(arc4random() % UInt32(cnt))
        return result
    }
    
    func cpuFlip(board:[[Int]], stone: Int) -> [(Int, Int)]? {
        if let places = canPlaced(board, stone: stone) {
            let (x, y) = places[ Int(getRandomNumber(places.count)) ]
            return flip(board, x: x, y: y, stone: stone)
        }
        return nil
    }
    
    func calcStones(board:[[Int]]) -> (free:Int, black:Int, white:Int) {
        var free = 0, white = 0, black = 0
        for y in 1...8 {
            for x in 1...8 {
                switch board[y][x] {
                case BLACK_STONE: black++
                case WHITE_STONE: white++
                default: free++
                }
            }
        }
        return (free, black, white)
    }
    
    func putStones(places:[(Int, Int)], stone: Int) {
        for (x, y) in places {
            board[y][x] = stone
        }
    }
    
    func flip(board:[[Int]], x:Int, y:Int, stone:Int) -> [(Int, Int)]? {
        if board[y][x] != EMPTY { return nil }
        var result:[(Int, Int)] = []
        result += flipLine(board, x: x, y: y, stone: stone, dx: 1, dy: 0)
        result += flipLine(board, x: x, y: y, stone: stone, dx:-1, dy: 0)
        result += flipLine(board, x: x, y: y, stone: stone, dx: 0, dy: 1)
        result += flipLine(board, x: x, y: y, stone: stone, dx: 0, dy:-1)
        result += flipLine(board, x: x, y: y, stone: stone, dx: 1, dy: 1)
        result += flipLine(board, x: x, y: y, stone: stone, dx:-1, dy:-1)
        result += flipLine(board, x: x, y: y, stone: stone, dx: 1, dy:-1)
        result += flipLine(board, x: x, y: y, stone: stone, dx:-1, dy: 1)
        
        if (result.count > 0) {
            result += [(x, y)]
            return result
        }
        
        return nil
    }
    
    func flipLine(board:[[Int]], x:Int, y:Int, stone:Int, dx:Int, dy:Int) -> [(Int, Int)] {
        var flipLoop: (x:Int, y:Int) -> [(Int, Int)]? = { _ in nil }
        flipLoop = { (x:Int, y:Int) -> [(Int, Int)]? in
            if board[y][x] == EMPTY {
                return nil
            } else if board[y][x] == stone {
                return []
            } else if var result = flipLoop(x: x + dx, y: y + dy) {
                result += [(x, y)]
                return result
            }
            return nil
        }
        if let result = flipLoop(x: x + dx, y: y + dy) {
            return result
        }
        return []
    }
    
    func flipLoop(board:[[Int]], x:Int, y:Int, stone:Int, dx:Int, dy:Int) -> [(Int, Int)]? {
        if board[y][x] == EMPTY {
            return nil
        } else if board[y][x] == stone {
            return []
        } else if var result = flipLoop(board, x: x + dx, y: y + dy, stone: stone, dx: dx, dy: dy) {
            result += [(x, y)]
            return result
        }
        return nil
    }
}