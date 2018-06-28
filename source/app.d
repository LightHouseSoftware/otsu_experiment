import std.algorithm;
import std.stdio;

import dlib.image;

// создать гистограмму
auto createHistogram(SuperImage superImage)
{
	int[256] histogram;

	foreach (x; 0..superImage.width)
	{
		foreach (y; 0..superImage.height)
		{
			int instensity = cast(int) (superImage[x,y].luminance * 255);
			histogram[instensity] += 1; 
		}
	}

	return histogram;
}

// посчитать порог по Оцу
auto calculateOtsuThreshold(SuperImage superImage)
{
	// вычисляем гистограмму
	auto histogram = createHistogram(superImage);

	// аккумулятор суммы яркостей
	int sumOfLuminances;

	// вычисляем сумму яркостей
	foreach (x; 0..superImage.width)
	{
		foreach (y; 0..superImage.height)
		{
			sumOfLuminances += cast(int) (superImage[x,y].luminance * 255); 
		}
	}

	// общее количество пикселей
	auto allPixelCount = cast(double) (superImage.width * superImage.height);
	
	// оптимальный порог
	int bestThreshold = 0;
	// количество полезных пикселей
    int firstClassPixelCount = 0;
    // суммарная яркость полезных пикселей
    int firstClassLuminanceSum = 0;
    
    // оптимальный разброс яркостей
    double bestSigma = 0.0;

    for (int threshold = 0; threshold < 255; threshold++)
    {
    	firstClassPixelCount += histogram[threshold];
        firstClassLuminanceSum += threshold * histogram[threshold];
    
    	// доля полезных пикселей
        double firstClassProbability = firstClassPixelCount / allPixelCount;
        // доля фоновых пикселей
        double secondClassProbability = 1.0 - firstClassProbability;

        // средняя доля полезных пикселей
        double firstClassMean = (firstClassPixelCount == 0) ? 0 : firstClassLuminanceSum / firstClassPixelCount;
        // средняя доля фоновых пикселей
        double secondClassMean = (sumOfLuminances - firstClassLuminanceSum) / (allPixelCount - firstClassPixelCount);
        // величина разброса 
        double meanDelta = firstClassMean - secondClassMean;
        // общий разброс
        double sigma = firstClassProbability * secondClassProbability * meanDelta * meanDelta;

        // находим оптимальный разброс
        if (sigma > bestSigma) 
        {
            bestSigma = sigma;
            bestThreshold = threshold;
        }
    }

    return bestThreshold;
}

// бинаризация по Оцу
auto otsuBinarization(SuperImage superImage)
{
	SuperImage newImage = image(superImage.width, superImage.height);
	auto threshold = calculateOtsuThreshold(superImage);

	foreach (x; 0..superImage.width)
	{
		foreach (y; 0..superImage.height)
		{
			auto luminance = cast(int) (superImage[x,y].luminance * 255);

			if (luminance > threshold)
			{
				newImage[x, y] = Color4f(1.0f, 1.0f, 1.0f);
			}
			else
			{
				newImage[x, y] = Color4f(0.0f, 0.0f, 0.0f);
			} 
		}
	}

	return newImage; 
}

void main()
{
	auto img = load("Lenna.png");
	img.otsuBinarization.savePNG("Lenna_binarizated.png");
}
