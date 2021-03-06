//
//  ChartLegendRenderer.swift
//  Charts
//
//  Created by Daniel Cohen Gindi on 4/3/15.
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/ios-charts
//

import Foundation
import CoreGraphics;

public class ChartLegendRenderer: ChartRendererBase
{   
    public override init(viewPortHandler: ChartViewPortHandler)
    {
        super.init(viewPortHandler: viewPortHandler);
    }

    /// Prepares the legend and calculates all needed forms and colors.
    public func computeLegend(data: ChartData, legend: ChartLegend!) -> ChartLegend
    {
        var labels = [String?]();
        var colors = [UIColor?]();
        
        // loop for building up the colors and labels used in the legend
        for (var i = 0, count = data.dataSetCount; i < count; i++)
        {
            var dataSet = data.getDataSetByIndex(i)!;

            var clrs: [UIColor] = dataSet.colors;
            var entryCount = dataSet.entryCount;
            
            // if we have a barchart with stacked bars
            if (dataSet.isKindOfClass(BarChartDataSet) && (dataSet as! BarChartDataSet).stackSize > 1)
            {
                var bds = dataSet as! BarChartDataSet;
                var sLabels = bds.stackLabels;

                for (var j = 0; j < clrs.count && j < bds.stackSize; j++) 
                {
                    labels.append(sLabels[j % sLabels.count]);
                    colors.append(clrs[j]);
                }

                // add the legend description label
                colors.append(UIColor.clearColor());
                labels.append(bds.label);

            }
            else if (dataSet.isKindOfClass(PieChartDataSet))
            {
                var xVals = data.xVals;
                var pds = dataSet as! PieChartDataSet;

                for (var j = 0; j < clrs.count && j < entryCount && j < xVals.count; j++)
                {
                    labels.append(xVals[j]);
                    colors.append(clrs[j]);
                }

                // add the legend description label
                colors.append(UIColor.clearColor());
                labels.append(pds.label);
            }
            else
            { // all others

                for (var j = 0; j < clrs.count && j < entryCount; j++)
                {
                    // if multiple colors are set for a DataSet, group them
                    if (j < clrs.count - 1 && j < entryCount - 1)
                    {
                        labels.append(nil);
                    }
                    else
                    { // add label to the last entry
                        labels.append(dataSet.label);
                    }

                    colors.append(clrs[j]);
                }
            }
        }

        var l = ChartLegend(colors: colors, labels: labels);

        if (legend !== nil)
        {
            // apply the old legend settings to a potential new legend
            l.apply(legend);
        }

        // calculate all dimensions of the legend
        l.calculateDimensions(l.font);

        return l;
    }

    public func renderLegend(#context: CGContext, legend: ChartLegend!)
    {
        if (legend === nil || !legend.enabled)
        {
            return;
        }
        
        var labelFont = legend.font;
        var labelTextColor = legend.textColor;
        var labelLineHeight = labelFont.lineHeight;

        var labels = legend.labels;

        var formSize = legend.formSize;

        // space between text and shape/form of entry
        var formTextSpaceAndForm = legend.formToTextSpace + formSize;

        // space between the entries
        var stackSpace = legend.stackSpace;

        // the amount of pixels the text needs to be set down to be on the same height as the form
        var textDrop = (labelFont.lineHeight + formSize) / 2.0;
        
        // contains the stacked legend size in pixels
        var stack = CGFloat(0.0);

        var wasStacked = false;

        var yoffset = legend.yOffset;
        var xoffset = legend.xOffset;
        
        switch (legend.position)
        {
            case .BelowChartLeft:

                var posX = viewPortHandler.contentLeft + xoffset;
                var posY = viewPortHandler.chartHeight - yoffset;

                for (var i = 0; i < labels.count; i++)
                {
                    drawForm(context, x: posX, y: posY - legend.textHeightMax / 2.0, colorIndex: i, legend: legend);

                    // grouped forms have null labels
                    if (labels[i] != nil)
                    {
                        // make a step to the left
                        if (legend.colors[i] != UIColor.clearColor())
                        {
                            posX += formTextSpaceAndForm;
                        }

                        drawLabel(context, x: posX, y: posY - legend.textHeightMax, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);
                        posX += (labels[i] as NSString!).sizeWithAttributes([NSFontAttributeName: labelFont]).width + legend.xEntrySpace;
                    }
                    else
                    {
                        posX += formSize + stackSpace;
                    }
                }

                break;
            case .BelowChartRight:

                var posX = viewPortHandler.contentRight - xoffset;
                var posY = viewPortHandler.chartHeight - yoffset;

                for (var i = labels.count - 1; i >= 0; i--)
                {
                    if (labels[i] != nil)
                    {
                        posX -= (labels[i] as NSString!).sizeWithAttributes([NSFontAttributeName: labelFont]).width + legend.xEntrySpace;
                        drawLabel(context, x: posX, y: posY - legend.textHeightMax, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);
                        if (legend.colors[i] != UIColor.clearColor())
                        {
                            posX -= formTextSpaceAndForm;
                        }
                    }
                    else
                    {
                        posX -= stackSpace + formSize;
                    }

                    drawForm(context, x: posX, y: posY - legend.textHeightMax / 2.0, colorIndex: i, legend: legend);
                }

                break;
            case .RightOfChart:

                var posX = viewPortHandler.chartWidth - legend.textWidthMax - xoffset;
                var posY = viewPortHandler.contentTop + yoffset;

                for (var i = 0; i < labels.count; i++)
                {
                    drawForm(context, x: posX + stack, y: posY, colorIndex: i, legend: legend);

                    if (labels[i] != nil)
                    {
                        if (!wasStacked)
                        {
                            var x = posX;

                            if (legend.colors[i] != UIColor.clearColor())
                            {
                                x += formTextSpaceAndForm;
                            }

                            drawLabel(context, x: x, y: posY - legend.textHeightMax / 2.0, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);

                            posY += textDrop;
                        }
                        else
                        {
                            posY += legend.textHeightMax * 3.0;
                            drawLabel(context, x: posX, y: posY - legend.textHeightMax * 2.0, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);
                        }

                        // make a step down
                        posY += legend.yEntrySpace;
                        stack = 0.0;
                    }
                    else
                    {
                        stack += formSize + stackSpace;
                        wasStacked = true;
                    }
                }
                break;
            case .RightOfChartCenter:
                var posX = viewPortHandler.chartWidth - legend.textWidthMax - xoffset;
                var posY = viewPortHandler.chartHeight / 2.0 - legend.neededHeight / 2.0;

                for (var i = 0; i < labels.count; i++)
                {
                    drawForm(context, x: posX + stack, y: posY, colorIndex: i, legend: legend);

                    if (labels[i] != nil)
                    {
                        if (!wasStacked)
                        {
                            var x = posX;

                            if (legend.colors[i] != UIColor.clearColor())
                            {
                                x += formTextSpaceAndForm;
                            }

                            drawLabel(context, x: x, y: posY - legend.textHeightMax / 2.0, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);

                            posY += textDrop;
                        }
                        else
                        {
                            posY += legend.textHeightMax * 3.0;
                            drawLabel(context, x: posX, y: posY - legend.textHeightMax * 2.0, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);
                        }

                        // make a step down
                        posY += legend.yEntrySpace;
                        stack = 0.0;
                    }
                    else
                    {
                        stack += formSize + stackSpace;
                        wasStacked = true;
                    }
                }

                break;
            case .BelowChartCenter:

                var posX = viewPortHandler.chartWidth / 2.0 - legend.neededWidth / 2.0;
                var posY = viewPortHandler.chartHeight - yoffset;

                for (var i = 0; i < labels.count; i++)
                {
                    drawForm(context, x: posX, y: posY - legend.textHeightMax / 2.0, colorIndex: i, legend: legend);

                    // grouped forms have null labels
                    if (labels[i] != nil)
                    {
                        // make a step to the left
                        if (legend.colors[i] != -2)
                        {
                            posX += formTextSpaceAndForm;
                        }

                        drawLabel(context, x: posX, y: posY - legend.textHeightMax, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);
                        posX += (labels[i] as NSString!).sizeWithAttributes([NSFontAttributeName: labelFont]).width + legend.xEntrySpace;
                    }
                    else
                    {
                        posX += formSize + stackSpace;
                    }
                }

                break;
            case .PiechartCenter:

                var posX = viewPortHandler.chartWidth / 2.0 - legend.textWidthMax / 2.0;
                var posY = viewPortHandler.chartHeight / 2.0 - legend.neededHeight / 2.0;

                for (var i = 0; i < labels.count; i++)
                {
                    drawForm(context, x: posX + stack, y: posY, colorIndex: i, legend: legend);

                    if (labels[i] != nil)
                    {
                        if (!wasStacked)
                        {
                            var x = posX;

                            if (legend.colors[i] != UIColor.clearColor())
                            {
                                x += formTextSpaceAndForm;
                            }

                            drawLabel(context, x: x, y: posY - legend.textHeightMax / 2.0, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);

                            posY += textDrop;
                        }
                        else
                        {
                            posY += legend.textHeightMax * 3.0;
                            drawLabel(context, x: posX, y: posY - legend.textHeightMax * 2.0, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);
                        }

                        // make a step down
                        posY += legend.yEntrySpace;
                        stack = 0.0;
                    }
                    else
                    {
                        stack += formSize + stackSpace;
                        wasStacked = true;
                    }
                }

                break;
            case .RightOfChartInside:
                var posX = viewPortHandler.chartWidth - legend.textWidthMax - xoffset;
                var posY = viewPortHandler.contentTop + yoffset;

                for (var i = 0; i < labels.count; i++)
                {
                    drawForm(context, x: posX + stack, y: posY, colorIndex: i, legend: legend);

                    if (labels[i] != nil)
                    {
                        if (!wasStacked)
                        {
                            var x = posX;

                            if (legend.colors[i] != UIColor.clearColor())
                            {
                                x += formTextSpaceAndForm;
                            }

                            drawLabel(context, x: x, y: posY - legend.textHeightMax / 2.0, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);

                            posY += textDrop;
                        }
                        else
                        {
                            posY += legend.textHeightMax * 3.0;
                            drawLabel(context, x: posX, y: posY - legend.textHeightMax * 2.0, label: legend.getLabel(i)!, font: labelFont, textColor: labelTextColor);
                        }

                        // make a step down
                        posY += legend.yEntrySpace;
                        stack = 0.0;
                    }
                    else
                    {
                        stack += formSize + stackSpace;
                        wasStacked = true;
                    }
                }
                break;
        }
    }

    /// Draws the Legend-form at the given position with the color at the given index.
    internal func drawForm(context: CGContext, x: CGFloat, y: CGFloat, colorIndex: Int, legend: ChartLegend)
    {
        var formColor = legend.colors[colorIndex];
        
        if (formColor === nil || formColor == UIColor.clearColor())
        {
            return;
        }
        
        var formsize = legend.formSize;
        
        CGContextSaveGState(context);
        
        switch (legend.form)
        {
        case .Circle:
            CGContextSetFillColorWithColor(context, formColor!.CGColor);
            CGContextFillEllipseInRect(context, CGRect(x: x, y: y - formsize / 2.0, width: formsize, height: formsize));
            break;
        case .Square:
            CGContextSetFillColorWithColor(context, formColor!.CGColor);
            CGContextFillRect(context, CGRect(x: x, y: y - formsize / 2.0, width: formsize, height: formsize));
            break;
        case .Line:
            
            CGContextSetLineWidth(context, legend.formLineWidth);
            CGContextSetStrokeColorWithColor(context, formColor!.CGColor);
            
            var lineSegments = UnsafeMutablePointer<CGPoint>.alloc(2)
            lineSegments[0] = CGPoint(x: x, y: y)
            lineSegments[1] = CGPoint(x: x + formsize, y: y)
            CGContextStrokeLineSegments(context, lineSegments, 2);
            lineSegments.dealloc(2);
            
            break;
        }
        
        CGContextRestoreGState(context);
    }

    /// Draws the provided label at the given position.
    internal func drawLabel(context: CGContext, x: CGFloat, y: CGFloat, label: String, font: UIFont, textColor: UIColor)
    {
        ChartUtils.drawText(context: context, text: label, point: CGPoint(x: x, y: y), align: .Left, attributes: [NSFontAttributeName: font, NSForegroundColorAttributeName: textColor]);
    }
}